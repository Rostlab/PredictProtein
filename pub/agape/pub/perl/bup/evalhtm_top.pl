#!/usr/sbin/perl -w
##!/usr/bin/perl -w
#----------------------------------------------------------------------
# evalhtm_top
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	evalhtm_top.pl list(.rdb_phd) files from PHD
#
# task:		in: list of PHDhtm RDB files, out: segment accuracy
#               
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost			October,        1995           #
#			changed:	January	,      	1996           #
#			changed:	February,      	1996           #
#			changed:	October,      	1996           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

$script_name      = "evalhtm_top";
$script_goal      = "in: list of PHDhtm RDB files, out: segment accuracy";
$script_input     = ".rdb_phd files from PHDhtm";
$script_opt_ar[1] = "output file";
$script_opt_ar[2] = "option for PHDx keys=both,sec,acc,htm,";
$script_opt_ar[3] = "option for mode = 'prd' (no observed data)";

push (@INC, "/home/rost/perl","/u/rost/perl/") ;
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
if ( ($#ARGV<1) ||  ($ARGV[1]=~/^help/) || ($ARGV[1]=~/^man/) ) { 
    print "$script_name '$script_input'\n";
    print "\t $script_goal\n";
    print "1st arg= list of RDB files\n";
    print "other  : keys=not_screen, file_out=name, fil,ref,ref2\n";
    print "        \n";
    print "------  \n";
    print "GENOME :\n";
    print "------  \n";
    print "         'prd' will extract information about prediction only\n";
    print "         nresMin=x  (skip proteins shorter than x)\n";
    print "         fileNali=x (reads ids with NALIGN - as grepped == HACK!!)\n";
    print "         nORF=x     (number of all ORF's, for percentages)\n";
    exit;}

#----------------------------------------
# read input
#----------------------------------------
$Lscreen=1;
$file_out= "unk";
$opt_phd=  "unk";
$opt=      "ref";
$file_in= $ARGV[1]; 	
$opt_phd=  "htm";
$Lprd_only=0;

$nresMin=  5;
$nexclNresMin=    0;		# number of proteins excluded as too short

foreach $_(@ARGV){
    if   (/^not_screen/){$Lscreen=0;}
    elsif(/^nresMin=/)  {$nresMin=$_;$nresMin=~s/^nresMin=|\s//g;}
    elsif(/^fileNali=/) {$fileNali=$_; $fileNali=~s/^fileNali=//g;}
    elsif(/^nORF=/)     {$nORF=$_; $nORF=~s/^nORF=//g;}
    elsif(/^.*out=/)    {$_=~s/^.*out=//g;
			 $file_out=$_;}
    elsif(/^nof/)       {$opt="nof";}
    elsif(/^fil/)       {$opt="fil";}
    elsif(/^ref2/)      {$opt="ref2";}
    elsif(/^ref/)       {$opt="ref";}
    elsif(/^top/)       {$opt="top";}
    elsif(/^prd/)       {$Lprd_only=1;}
} 

#------------------------------
# defaults
#------------------------------
if ($file_out eq "unk") {
    $tmp=$file_in;$tmp=~s/\.rdb.*$|\.list.*$//g;
    $file_out="Top-"."$tmp".".dat";
    if ($nresMin>10){
	$tmp="-excl".$nresMin;
	$file_out=~s/\.dat/$tmp\.dat/;}}

$file_out_det= $file_out;$file_out_det=~s/_ana/_det/; $file_out_det=~s/^Top-/Topdet-/;
$file_out_det2=$file_out;$file_out_det2=~s/_ana/_det/;$file_out_det2=~s/^Top-/Topdet2-/;
$file_out_statprd=$file_out;$file_out_statprd=~s/_ana/_det/;$file_out_statprd=~s/^Top-/Topstat-/;
$file_out_protprd=$file_out_statprd;$file_out_protprd=~s/Topstat-/Topprot-/;
$fhin=           "FHIN";$fhout2="FHOUT2";$fhout3="FHOUT3";$fhoutProt="FHOUT_PROT";
$fh=             "FHOUT";
$Lscreen=        1;
$file_names="/sander/purple1/rost/tm/swiss/setall-names.dat";


if    ($opt eq "fil") { $xout="PFHL"; @xtmp=("PHL","PFHL");}
elsif ($opt eq "nof") { $xout="PHL";  @xtmp=("PHL");}
elsif ($opt eq "ref") { $xout="PRHL"; @xtmp=("PHL","PRHL");}
elsif ($opt eq "ref2"){ $xout="PR2HL";@xtmp=("PHL","PR2HL");}
elsif ($opt eq "top") { $xout="PTHLA";@xtmp=("PHL","PTHLA");}

if ($Lprd_only) {
    @des_out=("AA","$xout","RI_S");
    @des_rd= ("AA",@xtmp,"RI_S");}
else {
    @des_out=("AA","OHL","$xout","RI_S");
    @des_rd= ("AA","OHL",@xtmp,"RI_S");}
@des_res=("Nok","Nobs","Nprd","Pok","Poks","Ri","RiD");

$symh=           "H";		# symbol for HTM
$des_aa=         $des_out[1];
$des_obs=        $des_out[2];
$des_phd=        $des_out[3];
if ($Lprd_only) { $des_phd=$des_out[2];}

$des_Nok=        $des_res[1];	# key for number of correctly predicted
$des_Nobs=       $des_res[2];	# key for number of observed helices
$des_Nprd=       $des_res[3];	# key for number of predicted helices
$des_Nprd2=      "Nprd2";	# key for number of predicted helices for 2nd best model
$des_Pok=        $des_res[4];	# key for number of proteins correctly predicted
				# correct number of helices(100%)
$des_Poks=       $des_res[5];	# key for number of proteins correctly predicted
				# if more HTM are allowed to be predicted in end
#$des_ri=         $des_res[6];	# key for reliability of refinement model (zscore)
$des_rip=        "Rip" ;	# key for reliability of refinement model (zscore)
$des_riD=        $des_res[7];	# key for reliability of refinement model (best-snd)

$des_top_prd=    "Tprd";
$des_top_obs=    "Tobs";
$des_top_rid=    "Trid";
$des_top_rip=    "Trip";
$des_TPok=       "TPok";
$des_TPokt=      "TPokt";
$des_TPokts=     "TPokts";

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
	    print "*** evalhtm_top: file '$_' missing \n";}}
    close($fhin);}
				# ------------------------------
				# read swissprot names (and store)
if (-e $file_names) {
    &open_file($fhin, "$file_names");
    while (<$fhin>){
	$_=~s/\n//g;
	($id,$de)=split(/\t/,$_);
	$id=~s/\s//g;
	$names{"$id"}=$de;}close($fhin);}

				# --------------------------------------------------
				# loop over all files
				# --------------------------------------------------
$ctfile=$#id=$#ri=$#riD=$#nprd2=$#top_prd=$#top_obs=$#top_rid=$#top_rip=0;
$#top_prd_all=$#top_prd_sep=$#top_nhtm_all=$#top_nhtm_sep=0;
$#top_rid_all=$#top_rid_sep=$#top_rip_all=$#top_rip_sep=0;
				# arguments for reading PHD.rdb
@rdb_arguments=("not_screen",
		"header","NHTM_BEST","NHTM_2ND_BEST","REL_BEST","REL_BEST_DIFF",
		"REL_BEST_DPROJ","HSSP_NALIGN","HSSP_THRESH");
if ($opt eq "top"){
    push(@rdb_arguments,"HTMTOP_PRD_A","HTMTOP_PRD_S","HTMTOP_NHTM_A","HTMTOP_NHTM_S",
	 "HTMTOP_RID_A","HTMTOP_RIP_A","HTMTOP_RID_S","HTMTOP_RIP_S");}
else {
    push(@rdb_arguments,"HTMTOP_PRD","HTMTOP_RID","HTMTOP_RIP"); }
if (! $Lprd_only){push(@rdb_arguments,"HTMTOP_OBS");}

				# print file: 1 line per protein
if ($Lprd_only){
    &open_file($fhoutProt, ">$file_out_protprd");
    printf $fhoutProt "%-s\t%-5s\t%-5s\t%-3s\t%-4s\t%-4s\t%-4s\t%-4s\n",
    "id","nres","nali","top","nhtm","2nd","riSeg","riTop";
	
				# read line 'NALIGN =' grepped from HSSP file
				# HACK 28-10-96
    if ( (defined $fileNali) && (-e $fileNali) ) {
	&open_file($fhin, "$fileNali");
	while(<$fhin>){if (length($_)<3){next;}
		       $_=~s/\n//g;
		       ($txt,$num)=split(/\s+/,$_);$num=~s/\s//g;
		       $txt=~s/^.*\///g;	# purge path
		       $txt=~s/\.hssp.*NALIGN//g;
		       $nali{"$txt"}=$num;}close($fhin);}
}


foreach $file_in (@file_in) {
    @tmp=
    %rd=&rd_rdb_associative($file_in,@rdb_arguments,
			    "body",@des_rd);
    if ($rd{"NROWS"}<$nresMin) {	# skip short ones
	++$nexclNresMin;
	next; }
    ++$ctfile;
    $id=$file_in;$id=~s/^.*\/([^\.]*)\..*/$1/;
    push(@id,$id);

    if ($opt=~/ref/){		# process header
	$rel_best= $rd{"REL_BEST"};$rel_best=~s/^.*\s+([\d\.]+)\s+.*$/$1/;$rel_best=~s/\s//g;
	$rel_bestD=$rd{"REL_BEST_DIFF"};$rel_bestD=~s/^.*\s+([\d\.]+)\s+.*$/$1/;
	$rel_bestp=$rd{"REL_BEST_DPROJ"};$rel_bestp=~s/^.*\s+([\d\.]+)\s+.*$/$1/;
	$rel_bestD=~s/\s//g;$rel_bestp=~s/\s//g;
	$nprd2=  $rd{"NHTM_2ND_BEST"};$nprd2=~s/^.*\s+([\d\.]+)\s+.*$/$1/;$nprd2=~s/\s|\n//g;
	push(@ri,$rel_best);push(@riD,$rel_bestD);push(@rip,$rel_bestp);push(@nprd2,$nprd2); }
    if (!$Lprd_only){
	$top_obs=$rd{"HTMTOP_OBS"}; $top_obs=~s/^.*\s+(\w+)\s+\(.*$/$1/g;
	push(@top_obs,$top_obs);}
				# for topology model
    if ($opt eq "top"){
	$ref_nhtm=$rd{"NHTM_BEST"};$ref_nhtm=~s/^.*\s+(\d+)\s+\(.*$/$1/g;
	$top_prd_all=$rd{"HTMTOP_PRD_A"}; $top_prd_all=~s/^.*\s+(\w+)\s+\(.*$/$1/g;
	$top_prd_sep=$rd{"HTMTOP_PRD_S"}; $top_prd_sep=~s/^.*\s+(\w+)\s+\(.*$/$1/g;
	$top_nhtm_all=$rd{"HTMTOP_NHTM_A"}; $top_nhtm_all=~s/^.*\s+(\d+)\s+\(.*$/$1/g;
	$top_nhtm_sep=$rd{"HTMTOP_NHTM_S"}; $top_nhtm_sep=~s/^.*\s+(\d+)\s+\(.*$/$1/g;
	$top_rid_all=$rd{"HTMTOP_RID_A"}; $top_rid_all=~s/^.*\s+([\d-.]+)\s+\(.*$/$1/g;
	$top_rid_sep=$rd{"HTMTOP_RID_S"}; $top_rid_sep=~s/^.*\s+([\d-.]+)\s+\(.*$/$1/g;
	$top_rip_all=$rd{"HTMTOP_RIP_A"}; $top_rip_all=~s/^.*\s+([\d-.]+)\s+\(.*$/$1/g;
	$top_rip_sep=$rd{"HTMTOP_RIP_S"}; $top_rip_sep=~s/^.*\s+([\d-.]+)\s+\(.*$/$1/g;
	push(@top_prd_all,$top_prd_all);push(@top_prd_sep,$top_prd_sep);
	push(@top_nhtm_all,$top_nhtm_all);push(@top_nhtm_sep,$top_nhtm_sep);
	push(@top_rid_all,$top_rid_all);push(@top_rid_sep,$top_rid_sep);
	push(@top_rip_all,$top_rip_all);push(@top_rip_sep,$top_rip_sep);}
    else {
	$top_prd=$rd{"HTMTOP_PRD"}; $top_prd=~s/^.*\s+(\w+)\s+\(.*$/$1/g;
	$top_rid=$rd{"HTMTOP_RID"}; $top_rid=~s/^.*\s+([-\d\.]+)\s*\(.*$/$1/g;
	$top_rip=$rd{"HTMTOP_RIP"}; $top_rip=~s/^.*\s+([-\d\.]+)\s*\(.*$/$1/g;
	push(@top_prd,$top_prd);push(@top_rid,$top_rid);push(@top_rip,$top_rip);
				# print file: 1 line per protein
	if ($Lprd_only){
	    $xnhtm= $rd{"NHTM_BEST"};     $xnhtm=~s/^.*\s+(\d+)\s+\(.*$/$1/g;
	    $xn2=   $rd{"NHTM_2ND_BEST"}; $xn2=~s/^.*\s+([\d\.]+)\s+.*$/$1/;$xn2=~s/\s|\n//g;
	    $xriseg=$rd{"REL_BEST_DPROJ"};$xriseg=~s/^.*\s+([\d\.]+)\s+.*$/$1/;
	    $xtop=  $rd{"HTMTOP_PRD"};    $xtop=~s/^.*\s+(\w+)\s+\(.*$/$1/g;
	    $xritop=$rd{"HTMTOP_RIP"};    $xritop=~s/^.*\s+([\d-.]+)\s+\(.*$/$1/g;
	    $idLoc=$id; $idLoc=~s/_.*$//g;
	    if (defined $rd{"HSSP_NALIGN"}){
		$nali=$rd{"HSSP_NALIGN"};}
	    elsif(defined $nali{"$idLoc"}){
		$rd{"HSSP_NALIGN"}=$nali{"$idLoc"};
		$nali=$nali{"$idLoc"};}
	    else {print "*** missing nali for idLoc=$idLoc, id=$id,\n";
		  $nali=0;}
				# hack to avoid errors in top
	    if (($xtop ne 'in')&&($xtop ne 'out')){$xtop='xxx';}
				# write
	    printf $fhoutProt "%-s\t%5d\t%5d\t%-3s\t%4d\t%4d\t%4d\t%4d\n",
	    $id,$rd{"NROWS"},$nali,$xtop,$xnhtm,$xn2,$xriseg,$xritop;}}


    $all{"$id","NROWS"}=$rd{"NROWS"};
    if (defined $rd{"HSSP_NALIGN"}){$all{"$id","HSSP_NALIGN"}=$rd{"HSSP_NALIGN"};}
    if (defined $rd{"HSSP_THRESH"}){$all{"$id","HSSP_THRESH"}=$rd{"HSSP_THRESH"};}
    foreach $des (@des_rd){
	$all{"$id","$des"}="";
	foreach $itres (1..$rd{"NROWS"}){
	    next if (!defined $rd{"$des","$itres"});
	    $all{"$id","$des"}.=$rd{"$des","$itres"}; }
				# convert L->" "
	if ($des=~/O.*L|P.*L/){
            if ($opt_phd eq "htm") {
                $all{"$id","$des"}=~s/E/ /g;}
	    $all{"$id","$des"}=~s/L/ /g;} }
    if ($opt eq "top"){
	$all{"$id","$des_top_rid","all"}=$top_rid_all;
	$all{"$id","$des_top_rid","sep"}=$top_rid_sep;
	$all{"$id","$des_top_rip","all"}=$top_rip_all;
	$all{"$id","$des_top_rip","sep"}=$top_rip_sep;
	$all{"$id","ref","nhtm"}=$ref_nhtm;
	$all{"$id","nhtm","all"}=$top_nhtm_all;$all{"$id","nhtm","sep"}=$top_nhtm_sep;
	$all{"$id","top","all"}= $top_prd_all;$all{"$id","top","sep"}=$top_prd_sep; }
    else {
	$all{"$id","$des_top_rid"}=$top_rid;
	$all{"$id","$des_top_rip"}=$top_rip;}
}
#%nali=0;			# hack 28-10-96 (set 0 to save space)

				# --------------------------------------------------
				# analyse segment accuracy
				# --------------------------------------------------
$idvec= ""; foreach $id (@id) {$idvec.="$id\t";} $idvec=~s/\t$//g;

if (!$Lprd_only){
    %res=
	&anal_seg($idvec,$symh,$des_obs,$des_phd,
		  $des_Nok,$des_Pok,$des_Poks,$des_Nobs,$des_Nprd,%all);}
else {
    %res=
	&anal_seg_prd($idvec,$symh,$des_aa,$des_phd,$des_Nprd,%all);
    &wrt_res_statprd($file_out_statprd,$fhout3,"STDOUT");
    if ($Lscreen) {
	&myprt_txt("evalhtm_top output in: \t $file_out_det2,$file_out_det,$file_out_statprd,"); 
	&myprt_txt("            single protein: \t '$file_out_protprd'");}
    exit;}
				# add ri
if ($opt=~/ref/){
    foreach $it(1..$#id){$res{"$id[$it]","$des_rip"}=$rip[$it];}
    foreach $it(1..$#id){$res{"$id[$it]","$des_riD"}=$riD[$it];}
    foreach $it(1..$#id){$res{"$id[$it]","$des_Nprd2"}=$nprd2[$it];}
}
&anal_top;
				# --------------------------------------------------
				# now write out
				# --------------------------------------------------
$desvec=""; foreach $des (@des_res){$desvec.="$des\t";} $desvec=~s/\t$//g;
$idvec= ""; foreach $id (@id) {$idvec.="$id\t";} $idvec=~s/\t$//g;

&compile_accmat;
&compile_random; 
&wrt_res("STDOUT",",",$opt,$idvec,$desvec,%res);

&open_file($fh, ">$file_out");
&wrt_res($fh,"\t",$opt,$idvec,$desvec,%res);
close($fh);


if ($Lscreen) {
    &myprt_txt("evalhtm_top output in file: \t '$file_out'"); &myprt_line; }
    
exit;

#==========================================================================================
sub anal_seg {
    local ($idvec,$symh,$des_obs,$des_phd,
	   $des_Nok,$des_Pok,$des_Poks,$des_Nobs,$des_Nprd,%all) = @_ ;
    local ($fh,@des,@id,$tmp,@tmp,$id,$it,$fhout);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    anal_seg                writes into file readable by EVALSEC
#--------------------------------------------------------------------------------
    $Lprt_det_old=1;
    if (defined %names) {$Lprt_det_new=1;}
				# vector to array
    @id=split(/\t/,$idvec);
    $ctprot_ok=$ctprot_oksucc=$ctres_ok=$ctres_obs=$ctres_phd=0;
    $fhout="FHOUT_SEG";

    &open_file($fhout, ">$file_out_det");
    if ($Lprt_det_new){
	&open_file($fhout2, ">$file_out_det2");}
    if ($Lscreen){push(@fhx,"STDOUT",$fhout2);}else{@fhx=($fhout2);}
    
    if ($Lprt_det_old){printf $fhout "\t   %3s\t   %3s\n","obs","prd";}

    foreach $it (1..$#id){
	$id=$id[$it];
	%obs=%phd=0;		# ini
				# note: $x{"$symh","beg","$it"}
	%obs= &get_secstr_segment_caps($all{"$id","$des_obs"},$symh);
	%phd= &get_secstr_segment_caps($all{"$id","$des_phd"},$symh);

	$ctres_obs+=$obs{"$symh","NROWS"};
	$ctres_phd+=$phd{"$symh","NROWS"};
	$idprt=$id;$idprt=~s/_ref.*|_nof.*|_fil.*//g;
	foreach $fhx(@fhx){
	    if ($Lprt_det_new) {
		printf $fhx "%-15s\t%-s\n",$idprt,$names{"$idprt"};}}
				# ini
	foreach $it(1..$phd{"$symh","NROWS"}){$Lok[$it]=1;}
	$ctok=$ctsucc=$ctprt=$#txt_match=0;
	foreach $ctphd (1..$phd{"$symh","NROWS"}){$Lflag_phd[$ctphd]=0;} 

	foreach $ctobs (1..$obs{"$symh","NROWS"}) {
	    foreach $ctphd (1..$phd{"$symh","NROWS"}) {
		next if ($Lflag_phd[$ctphd]);
#		last if ($phd{"$symh","beg","$ctphd"}>$obs{"$symh","end","$ctobs"});
		if ($phd{"$symh","end","$ctphd"}<$obs{"$symh","beg","$ctobs"}){
		    if ($Lprt_det_new) {
			++$ctprt;
			$Lflag_phd[$ctphd]=1;
			$prtobs[$ctprt]=" - ";
			$prtphd[$ctprt]=
			    $phd{"$symh","beg","$ctphd"}."-".$phd{"$symh","end","$ctphd"};}
		    next;}
		elsif ($obs{"$symh","end","$ctobs"}<$phd{"$symh","beg","$ctphd"}){
		    if ($Lprt_det_new) {
			++$ctprt;
			$prtobs[$ctprt]=
			    $obs{"$symh","beg","$ctobs"}."-".$obs{"$symh","end","$ctobs"};
			$prtphd[$ctprt]=" - ";}
		    last;}
		elsif (($phd{"$symh","beg","$ctphd"}<($obs{"$symh","end","$ctobs"}-3))||
		       ($phd{"$symh","end","$ctphd"}>($obs{"$symh","beg","$ctobs"}+3))){
		    if ($Lok[$ctphd]){
			if ($ctok==0){$fst_phd=$ctphd;}
			if (($ctobs==$ctphd)||(($ctphd-$fst_phd+1)==$ctobs)){
			    ++$ctsucc;}
			push(@txt_match,"$ctobs-$ctphd");
			if ($Lprt_det_new) {
			    ++$ctprt;
			    $Lflag_phd[$ctphd]=1;
			    $prtobs[$ctprt]=
				$obs{"$symh","beg","$ctobs"}."-".$obs{"$symh","end","$ctobs"};
			    $prtphd[$ctprt]=
				$phd{"$symh","beg","$ctphd"}."-".$phd{"$symh","end","$ctphd"};}
			$Lok[$ctphd]=0;
			++$ctok;
			last;}}}}
				# print detail
	if (defined $top_prd[$it]){$top_prd=$top_prd[$it];}else{$top_prd=$top_prd_sep[$it];}
	if ( $Lprt_det_old ){
	    $nobs=$obs{"$symh","NROWS"};$nprd=$phd{"$symh","NROWS"};$ctprd=$ctobs=1;
	    printf $fhout "%-s\; %-s\n",$idprt,$names{"$idprt"};
	    $top_obs=$top_obs[$it];$top_obs=~tr/[a-z]/[A-Z]/;
	    $tmp=$top_prd;$tmp=~tr/[a-z]/[A-Z]/;
	    printf $fhout "\t   %3s\t   %3s\n",$top_obs,$tmp;
	    while( ($ctobs<=$nobs) || ($ctprd<=$nprd) ) {
		if ($#txt_match>0){$tmp=shift(@txt_match);
				   ($obs,$prd)=split(/-/,$tmp);}
		else {$obs=($nobs+1);$prd=($nprd+1);}
		while ($ctobs < $obs){
		    printf $fhout "\t%3d-%3d\t%3s %3s\n",
		    $obs{"$symh","beg","$ctobs"},$obs{"$symh","end","$ctobs"}," "," ";++$ctobs;}
		while ($ctprd < $prd) {
		    printf $fhout "\t%3s %3s\t%3d-%3d\n"," "," ",
		    $phd{"$symh","beg","$ctprd"},$phd{"$symh","end","$ctprd"};++$ctprd;}
		if( ($ctobs<=$nobs) && ($ctprd<=$nprd) ) {
		    printf $fhout "\t%3d-%3d\t%3d-%3d\n",
		    $obs{"$symh","beg","$obs"},$obs{"$symh","end","$obs"},
		    $phd{"$symh","beg","$prd"},$phd{"$symh","end","$prd"};}
		++$ctobs;++$ctprd;}}

	$tmpseg=$ctprt;
	if ($Lprt_det_new){
	    foreach $fhx (@fhx){
		printf $fhx "%5s %3s %-5s\t"," ","obs",$top_obs[$it];
		foreach $ctprt (1..$tmpseg){
		    if (defined $prtobs[$ctprt]){
			printf $fhx "%-11s ",$prtobs[$ctprt];}
		    else { printf $fhx "%-11s "," ";}}
		print $fhx "\n";
		printf $fhx "%5s %3s %-5s\t"," ","prd",$top_prd;
		foreach $ctprt (1..$tmpseg){
		    if (defined $prtphd[$ctprt]){
			printf $fhx "%-11s ",$prtphd[$ctprt];}
		    else { printf $fhx "%-11s "," ";}}
		print $fhx "\n"; }}
	$res{"$id","$des_Nok"}= $ctok;
	$res{"$id","$des_Nobs"}=$obs{"$symh","NROWS"};
	$res{"$id","$des_Nprd"}=$phd{"$symh","NROWS"};
	$res{"$id","$des_Pok"}=0;
	$res{"$id","$des_Poks"}=0;
	$ctres_ok+=$ctok;
	if (($obs{"$symh","NROWS"}==$phd{"$symh","NROWS"}) &&
	    ($obs{"$symh","NROWS"}==$ctok)){
	    $res{"$id","$des_Pok"}=100;
	    ++$ctprot_ok;}
	if ($obs{"$symh","NROWS"}==$ctsucc){
	    $res{"$id","$des_Poks"}=100;
	    ++$ctprot_oksucc;}
    }
    close($fhout);		# file for details
    $res{"NROWS"}=$#id;
    $res{"$des_Pok"}=$ctprot_ok;
    $res{"$des_Poks"}=$ctprot_oksucc;
    $res{"$des_Nobs"}=$ctres_obs;
    $res{"$des_Nprd"}=$ctres_phd;
    $res{"$des_Nok"}=$ctres_ok;
    return(%res);
}				# end of anal_seg

#==========================================================================================
sub anal_seg_prd {
    local ($idvec,$symh,$des_aa,$des_phd,$des_Nprd,%all) = @_ ;
    local ($fh,@des,@id,$tmp,@tmp,$id,$it,$fhout);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    anal_seg_prd            writes into file readable by EVALSEC
#--------------------------------------------------------------------------------
    $Lprt_det_old=1;
    if (defined %names) {$Lprt_det_new=1;}
    $Lprt_det_new=1;
				# vector to array
    @id=split(/\t/,$idvec);
    $ctres_phd=0;
    $fhout="FHOUT_SEG";

    if ($Lprt_det_old){&open_file($fhout, ">$file_out_det");}
    if ($Lprt_det_new){&open_file($fhout2, ">$file_out_det2");}
    if ($Lscreen){push(@fhx,"STDOUT",$fhout2);}else{@fhx=($fhout2);}
				# header for old
    if ($Lprt_det_old){printf $fhout  "\t   %3s\n","prd";}
    if ($Lprt_det_new){printf $fhout2 
			   "%-10s\t%-3s\t%4s\t%4s\t%4s\t%-10s\t%-10s\t%-s\n",
			   "id","Top","Nhtm","Nali","Thssp","1st 10res","segments","name";}
    $max_nprd=0;
    foreach $it (1..$#id){
	$id=$id[$it];		# note: $x{"$symh","beg","$it"}
	%phd= &get_secstr_segment_caps($all{"$id","$des_phd"},$symh);
	$ctres_phd+=$phd{"$symh","NROWS"};
	$idprt=$id;$idprt=~s/_ref.*|_nof.*|_fil.*//g;
	$top_prd=$top_prd[$it];
#	$top_prd=~tr/[a-z]/[A-Z]/;
	$nprd=$phd{"$symh","NROWS"};
	$res{"$id","$des_Nprd"}=$phd{"$symh","NROWS"};
				# ------------------------------
				# statistics
	if (defined $res{"$nprd","$top_prd"}){++$res{"$nprd","$top_prd"};}
	else {$res{"$nprd","$top_prd"}=1;}
	if ($nprd>$max_nprd){$max_nprd=$nprd;}
				# ------------------------------
	if ( $Lprt_det_old ){	# print detail (old one, columns)
	    if (defined $names{"$idprt"}){
		printf $fhout "%-s\; %-s\n",$idprt,$names{"$idprt"};
		printf $fhout "\t   %3s\n",$top_prd;}
	    foreach $ctphd(1..$phd{"$symh","NROWS"}){
		printf $fhout
		    "\t%3d-%3d\n",$phd{"$symh","beg","$ctphd"},$phd{"$symh","end","$ctphd"};}}
				# ------------------------------
	if ($Lprt_det_new){	# print detail (new: rows)
	    $tmpaa=substr($all{"$id","$des_aa"},1,10);
	    $nalign=$thresh=0;	# number of sequences in HSSP file
	    if (defined $all{"$id","HSSP_NALIGN"}){$nalign=$all{"$id","HSSP_NALIGN"};}
	    if (defined $all{"$id","HSSP_THRESH"}){$thresh=$all{"$id","HSSP_THRESH"};}
	    $nalign=~s/\D//g;$thresh=~s/\D//g;
	    foreach $fhx (@fhx){
		printf $fhx 
		    "%-10s\t%-3s\t%4d\t%4d\t%4d\t%-10s\t",
		    $idprt,$top_prd,$phd{"$symh","NROWS"},$nalign,$thresh,$tmpaa;
		foreach $ctphd (1..$phd{"$symh","NROWS"}) {
		    $tmp=$phd{"$symh","beg","$ctphd"}."-".$phd{"$symh","end","$ctphd"};
		    print $fhx "$tmp,";}
		if (defined $names{"$idprt"}){
		    printf $fhx "\t%-s\n",$names{"$idprt"};}else {printf $fhx "\n";}}}
    }
    close($fhout);		# file for details
    $res{"NROWS"}=$#id;
    $res{"$des_Nprd"}=$ctres_phd;
				# count various
    foreach $des ("in","out"){$res{"$des"}=0;}
    foreach $ct (1..$max_nprd){
	foreach $des ("in","out"){
	    if (! defined $res{"$ct","$des"} ){$res{"$ct","$des"}=0;}}
	$res{"$ct","sum"}=$res{"$ct","in"}+$res{"$ct","out"};
	foreach $des ("in","out"){
	    $res{"$des"}+=$res{"$ct","$des"};}}
    return(%res);
}				# end of anal_seg_prd

#==========================================================================================
sub anal_top {
#    local ($file_in, $chain_in, $skip) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    anal_top                   analyse topology 
#--------------------------------------------------------------------------------
    %accmat=0;			# accuracy matrix (obs,prd)
				# store topology
    foreach $it(1..$#id){$res{"$id[$it]","$des_top_prd"}=$top_prd[$it];}
    foreach $it(1..$#id){$res{"$id[$it]","$des_top_obs"}=$top_obs[$it];}
    foreach $it(1..$#id){$res{"$id[$it]","$des_top_rid"}=$top_rid[$it];}
    $ok=$okt=$okts=$ct=0;		# analyse
    foreach $it(1..$#id){
	$id=$id[$it];
				# ini
	$res{"$id","$des_TPok"}=$res{"$id","$des_TPokt"}=$res{"$id","$des_TPokts"}=0;
	if    (defined $top_prd[$it])     {$top_prd=$top_prd[$it];}
	elsif (defined $top_prd_sep[$it]) {$top_prd=$top_prd_sep[$it];}
	else {
	    next;}
	if ( $top_obs[$it] eq "unk" ){
	    next;}
	++$ct;			# topology prd=obs
	++$accmat{"$top_obs[$it]","$top_prd"};
	if ( $top_prd eq $top_obs[$it] ) {
	    ++$okt;$res{"$id","$des_TPokt"}=100;
	    if    ($res{"$id","$des_Pok"}>0){
		++$ok;++$okts;$res{"$id","$des_TPok"}=100;$res{"$id","$des_TPokts"}=100;}
	    elsif ($res{"$id","$des_Poks"}>0){
		++$okts;$res{"$id","$des_TPokts"}=100;} }
    }
    if ($ct>0){
	$res{"$des_TPok"}=  $ok;
	$res{"$des_TPokt"}= $okt;
	$res{"$des_TPokts"}=$okts; 
	$res{"top_known"}=  $ct;}
    else {
	$res{"$des_TPok"}=$res{"$des_TPokt"}=$res{"$des_TPokts"}=999;$res{"top_known"}=0;}
}				# end of anal_top

#==========================================================================================
sub compile_accmat {
    $[ =1 ;
#--------------------------------------------------------------------------------
#    compile_accmat             computes accuracy matrix (4 x 4) for topology pred
#--------------------------------------------------------------------------------
    %sum=%q=0;
				# --------------------
    foreach $obs ("in","out"){	# sum over observed
	foreach $prd ("in","out"){
	    if (defined $sum{"$obs","obs"}) {
		$sum{"$obs","obs"}+=$accmat{"$obs","$prd"};}
	    else {
		$sum{"$obs","obs"}=$accmat{"$obs","$prd"};}}
	if (defined $sum{"obs"}){ # total sum
	    $sum{"obs"}+=$sum{"$obs","obs"};}
	else {$sum{"obs"}=$sum{"$obs","obs"};}}
				# --------------------
    foreach $prd ("in","out"){	# sum over predicted
	foreach $obs ("in","out"){
	    if (defined $sum{"$prd","prd"}) { 
		$sum{"$prd","prd"}+=$accmat{"$obs","$prd"};}
	    else {
		$sum{"$prd","prd"}=$accmat{"$obs","$prd"};}}
	if (defined $sum{"prd"}){
	    $sum{"prd"}+=$sum{"$prd","prd"};}
	else {$sum{"prd"}=$sum{"$prd","prd"};} }
				# --------------------
    foreach $prd ("in","out"){	# sum over correct predicted
	if (defined $sum{"ok","prd"}){
	    $sum{"ok","prd"}+=$accmat{"$prd","$prd"};}
	else {
	    $sum{"ok","prd"}=$accmat{"$prd","$prd"};}}
				# --------------------
    foreach $des ("in","out"){	# quotients
	if ($sum{"$des","obs"}>0) { #  Q %obs
	    $q{"$des","obs"}=100*($accmat{"$des","$des"}/$sum{"$des","obs"});}
	else{$q{"$des","obs"}=0;}
	if ($sum{"$des","prd"}>0) { #  Q %prd
	    $q{"$des","prd"}=100*($accmat{"$des","$des"}/$sum{"$des","prd"});}
	else{$q{"$des","prd"}=0;}
    }				# final Q2
    if ($sum{"obs"}>0){$q{"q2"}=100*($sum{"ok","prd"}/$sum{"obs"}); } else {$q{"q2"}=0;}
				# consistency check
    if ($sum{"prd"} != $sum{"obs"}) {
	print "*** ERROR compile_accmat: N prd=",$sum{"prd"}," != N obs=",$sum{"obs"},"\n";
	&wrt_res_accmat("STDOUT");
	exit; }
}				# end of compile_accmat

#==========================================================================================
sub compile_random {
    $[ =1 ;
#--------------------------------------------------------------------------------
#    compile_random             computes accuracy matrix (4 x 4) for topology pred
#--------------------------------------------------------------------------------
				# two different scenarios: flipping coin,
				# or compute preferences
    $Lcoin=1;$Lprob=0;
    $Lcoin=0;$Lprob=1;
    $Lcoin=1;$Lprob=1;
				# compute ratios for current data base
    foreach $des ("in","out"){if ($sum{"obs"}){
	$ran{"$des","prob"}=$sum{"$des","obs"}/$sum{"obs"};} else {$ran{"$des","prob"}=0;}}
    $ran{"in","prob"}= 0.402;
    $ran{"out","prob"}=0.598;
				# ------------------------------
				# flipping coin experiment
    if ($Lcoin) {
	foreach $des ("in","out"){ $ran{"$des","coin"}=0;} # initialise
	foreach $id (@id){
	    $tmp= rand ;
	    if ( ($tmp>=$ran{"in","prob"}) && ($res{"$id","$des_top_obs"} eq "out") ) {
		++$ran{"out","coin"};}
	    elsif ( ($tmp<$ran{"in","prob"}) && ($res{"$id","$des_top_obs"} eq "in") ) {
		++$ran{"in","coin"};}}
	$ran{"q2","coin"}=100*( ($ran{"in","coin"}+$ran{"out","coin"})/$sum{"obs"} ); 
	foreach $des ("in","out"){
	    $ran{"$des","coin"}=100*($ran{"$des","coin"}/$sum{"$des","obs"});}}
    
				# ------------------------------
				# compute random accuracy by preferences
    if ($Lprob) {
	$sum=0;
	foreach $des ("in","out"){
	    $ran{"$des","pref"}=100*($ran{"$des","prob"}*$sum{"$des","obs"}/$sum{"obs"});
	    $ran{"$des","pref"}=100*($ran{"$des","prob"});
	    $sum+=$ran{"$des","pref"}*$sum{"$des","obs"};}
	$ran{"q2","pref"}=$sum/$sum{"obs"}; }
}				# end of compile_random

#==========================================================================================
sub wrt_res {
    local ($fh,$sep,$opt,$idvec,$desvec,%res) = @_ ;
    local (@des,@id,$tmp,$tmp_qobs,$tmp_qprd,$id,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_res                writes into file readable by EVALSEC
#--------------------------------------------------------------------------------
				# vector to array
    @des=split(/\t/,$desvec);
    @id=split(/\t/,$idvec);
    foreach $_(@des){if (/prot.*ok/){$des_Pok=$_;last;}}

    $top_known=$res{"top_known"};if ($top_known==0){$tmp_known=1;}else{$tmp_known=$top_known;}

				# ------------------------------
				# header
    if ($res{"NROWS"}>0){$tmp=$res{"$des_Pok"}/$res{"NROWS"};}else{$tmp=0;}
    
    if ($sep eq "\t") {
	print  $fh "# Perl-RDB\n";}
    print  $fh "# final averages:\n";
    printf $fh "# Nok   :%6s,%4d   (N seg correct)\n"," ",$res{"$des[1]"};
    printf $fh "# Nobs  :%6s,%4d   (N seg observed)\n"," ",$res{"$des[2]"};
    printf $fh "# Nprd  :%6s,%4d   (N seg predicted)\n"," ",$res{"$des[3]"};
    printf $fh "# Nprot :%6s,%4d   (N proteins)\n"," ",$res{"NROWS"};
    printf $fh "# Pok   :%6.1f,%4d   (P correct)\n",
                         100*($res{"$des_Pok"}/$#id),$res{"$des_Pok"};
    printf $fh "# Poks  :%6.1f,%4d   (P corr succession)\n",
                         100*($res{"$des_Poks"}/$#id),$res{"$des_Poks"};
    printf $fh "# Tknown:%6s,%4d   (N proteins with known topology)\n"," ",$top_known;
    printf $fh "# TPok  :%6.1f,%4d   (P topology and Nseg correct)\n",
                         100*($res{"$des_TPok"}/$tmp_known),$res{"$des_TPok"};
    printf $fh "# TPokts:%6.1f,%4d   (P topology and succession correct)\n",
                         100*($res{"$des_TPokts"}/$tmp_known),$res{"$des_TPokts"};
    printf $fh "# TPokt :%6.1f,%4d   (P topology correct Nseg not)\n",
                         100*($res{"$des_TPokt"}/$tmp_known),$res{"$des_TPokt"};
    printf $fh "#       :%6.1f,%4s   (top corr as percentage of proteins with corr seg)\n",
                         100*($res{"$des_TPok"}/$res{"$des_Pok"})," ";
    printf $fh "#    \n";
				# print final accuracy matrix
    &wrt_res_accmat($fh);

    if ($fh ne "STDOUT"){
	printf $fh "#    \n";
	printf $fh "# NOTATION: Pok        number of proteins with Nhtm pred=obs=ok\n";
	printf $fh "# NOTATION: Pok(id)    100 or 0, \n";
	printf $fh "# NOTATION: Poks       at least 'core' same number, i.e., succession ok\n";
	printf $fh "# NOTATION: Poks(id)   100 or 0, \n";
	printf $fh "# NOTATION: Ri         reliability of refinement model (zscore)\n";
	printf $fh "# NOTATION: RiD        reliability of refinement model (best-snd/len)\n";
	printf $fh "# NOTATION: Rip           as previous projected onto scale 0-9\n";
	printf $fh "# NOTATION: TRiD       difference content K+R (even-odd)\n";
	printf $fh "# NOTATION: TRip       int( min{9,sqrt(TRiD**2)} )\n";
	printf $fh "#  \n";}
				# ------------------------------
				# names
    printf $fh "%-11s$sep","id";
    printf $fh "%4s$sep%4s$sep%4s$sep",$des_Nok,$des_Nobs,$des_Nprd;
    if ($opt eq "top"){printf $fh "%4s$sep%4s$sep","NTa","NTs";}
    printf $fh "%3s$sep%3s$sep",$des_Pok,"Pos";
    if ($opt=~/ref/)  {printf $fh "%4s$sep","Np2"; # correct to shorter name
		       printf $fh "%3s$sep%5s$sep",$des_rip,$des_riD;}
    if ($opt eq "top"){printf $fh "%3s$sep%3s$sep%3s$sep","Tob","Tpa","Tps";}
    else {printf $fh "%3s$sep%3s$sep","Tob","Tprd";}
    printf $fh "%4s$sep%4s$sep","Qobs","Qprd";
    if ($opt eq "top"){
	printf $fh "%5s$sep%5s$sep%5s$sep%5s$sep","TRiDa","TRiPa","TRiDs","TRiPs";}
    else {printf $fh "%4s$sep%4s$sep","TRiD","TRip";}
    printf $fh "%4s$sep%4s$sep%4s\n","Tokt","Toks","TPok";
				# ------------------------------
				# formats for RDB
    if ($sep eq "\t") {printf $fh "%-11s$sep","11";
		       printf $fh "%4s$sep%4s$sep%4s$sep","4N","4N","4N";
		       if ($opt eq "top"){
			   printf $fh "%4s$sep%4s$sep","4N","4N";}
		       printf $fh "%3s$sep%3s$sep","3N","3N";
		       if ($opt=~/ref/){
			   printf $fh "%4s$sep%5s$sep%5s$sep","4N","3N","5.3F";}
		       printf $fh "%3s$sep%3s$sep","3","3";
		       if ($opt eq "top"){printf $fh "%3s$sep","3";}
		       if ($opt eq "top"){
			   printf $fh "%4s$sep%4s$sep%4s$sep%4s$sep","4N","4N","4N","4N";}
		       else{printf $fh "%4s$sep%4s$sep","4N","4N";}
		       printf $fh "%4s$sep%4s$sep","4N","4N";
		       printf $fh "%4s$sep%4s$sep%4s\n","4N","4N","4N";}

				# ------------------------------
				# all proteins
    $qobs=$qprd=$ri=$rip=$riD=$Nprd2=$top_rid=$top_rip=0;
    $top_rip_all=$top_rip_sep=$top_rid_all=$top_rid_sep=$nhtm_all=$nhtm_sep=0;
    foreach $it (1..$#id) {
	if ($opt eq "top"){ $res{"$id","$des_Nprd"}=$all{"$id","ref","nhtm"};}
	$id=$id[$it];
	$idprt=$id;$idprt=~s/_refpb|_refp|_ref|_fil|_nof|_top.*$//g;
	printf $fh "%-11s$sep","$idprt";
	printf $fh 
	    "%4d$sep%4d$sep%4d$sep",$res{"$id","$des_Nok"},
	    $res{"$id","$des_Nobs"},$res{"$id","$des_Nprd"};
	if ($opt eq "top"){
	    $nhtm_all+=$all{"$id","nhtm","all"};$nhtm_sep+=$all{"$id","nhtm","sep"};
	    printf $fh 
		"%4d$sep%4d$sep",$all{"$id","nhtm","all"},$all{"$id","nhtm","sep"};}
	printf $fh "%3d$sep%3d$sep",$res{"$id","$des_Pok"},$res{"$id","$des_Poks"};
	if ($opt=~/ref/){
#	    $tmp_ri=   $res{"$id","$des_ri"};
	    $tmp_rip=  $res{"$id","$des_rip"};
	    $tmp_riD=  $res{"$id","$des_riD"};
	    $tmp_Nprd2=$res{"$id","$des_Nprd2"};
	    printf $fh 
		"%4d$sep%3d$sep%5.3f$sep",$res{"$id","$des_Nprd2"},
		$res{"$id","$des_rip"},$res{"$id","$des_riD"};
	    $rip+=$tmp_rip;$riD+=$tmp_riD;$Nprd2+=$tmp_Nprd2;}
	if ($opt eq "top"){
	    printf $fh 
		"%3s$sep%3s$sep%3s$sep",$res{"$id","$des_top_obs"},
		$all{"$id","top","all"},$all{"$id","top","sep"};}
	else {
	    printf $fh "%3s$sep%3s$sep",$res{"$id","$des_top_obs"},$res{"$id","$des_top_prd"};}
	if ($res{"$id","$des[2]"}>0) {
	    $tmp_qobs=100*($res{"$id","$des[1]"}/$res{"$id","$des[2]"});}
	else {$tmp_qobs=0;}
	if ($res{"$id","$des[3]"}>0) {
	    $tmp_qprd=100*($res{"$id","$des[1]"}/$res{"$id","$des[3]"});}
	else {$tmp_qprd=0;}
	$qobs+=$tmp_qobs;$qprd+=$tmp_qprd;	# sum
	printf $fh "%4d$sep%4d$sep",int($tmp_qobs),int($tmp_qprd);
	if ($opt eq "top"){
	    $top_rid_all+=&func_absolute($all{"$id","$des_top_rid","all"});
	    $top_rip_all+=$all{"$id","$des_top_rip","all"};
	    $top_rid_sep+=&func_absolute($all{"$id","$des_top_rid","sep"});
	    $top_rip_sep+=$all{"$id","$des_top_rip","sep"};
	    printf $fh 
		"%4d$sep%4d$sep%4d$sep%4d$sep",
		$all{"$id","$des_top_rid","all"},$all{"$id","$des_top_rip","all"},
		$all{"$id","$des_top_rid","all"},$all{"$id","$des_top_rip","all"};}
	else {
	    $top_rid+=sqrt($all{"$id","$des_top_rid"}*$all{"$id","$des_top_rid"});
	    $top_rip+=$all{"$id","$des_top_rip"};
	    printf $fh "%4d$sep%4d$sep",$all{"$id","$des_top_rid"},$all{"$id","$des_top_rip"};}
	printf $fh 
	    "%4d$sep%4d$sep%4d\n",$res{"$id","$des_TPokt"},$res{"$id","$des_TPokts"},
	    $res{"$id","$des_TPok"};
    }
				# averages over all proteins
    printf $fh "%-11s$sep","all $#id";
    printf $fh "%4d$sep%4d$sep%4d$sep",$res{"$des_Nok"},$res{"$des_Nobs"},$res{"$des_Nprd"};
    if ($opt eq "top"){
	printf $fh "%4d$sep%4d$sep",$nhtm_all,$nhtm_sep;}
    printf $fh 
	"%3d$sep%3d$sep",int(100*($res{"$des_Pok"}/$#id)),int(100*($res{"$des_Poks"}/$#id));
    if ($opt=~/ref/){
	$tmp1=$rip/$#id;$tmp2=$riD/$#id;$tmp_Nprd2=$Nprd2/$#id;
	printf $fh "%4d$sep%3.1f$sep%5.3f$sep",$tmp_Nprd2,$tmp1,$tmp2;}
    printf $fh "%3s$sep%3s$sep"," "," ";
    if ($opt eq "top"){printf $fh "%3s$sep"," ";}
    printf $fh "%4d$sep%4d$sep",int($qobs/$#id),int($qprd/$#id);
    if ($opt eq "top"){
	printf $fh 
	    "%4d$sep%4d$sep%4d$sep%4d$sep",
	    int($top_rid_all/$tmp_known),int($top_rip_all/$tmp_known),
	    int($top_rid_sep/$tmp_known),int($top_rip_sep/$tmp_known);}
    else {
	printf $fh "%4d$sep%4d$sep",int($top_rid/$tmp_known),int($top_rip/$tmp_known);}
    printf $fh 
	"%4d$sep%4d$sep%4d\n",int(100*($res{"$des_TPokt"}/$tmp_known)),
	int(100*($res{"$des_TPokts"}/$tmp_known)),int(100*($res{"$des_TPok"}/$tmp_known));
}				# end of wrt_res

#==========================================================================================
sub wrt_res_accmat {
    local ($fh) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_res_accmat             computes and writes accuracy matrix (4 x 4) for
#                               the topology prediction
#--------------------------------------------------------------------------------
    if (defined $ran{"q2","coin"}) {$Lcoin=1;}else{$Lcoin=0;}
    if (defined $ran{"q2","pref"}) {$Lpref=1;}else{$Lpref=0;}
				# ------------------------------
				# now print
    $txt="# ACCMAT ";
				# header
    &wrt_res_accmat_header($fh,$txt,$Lcoin,$Lpref);
    &wrt_res_accmat_line($fh,$txt,$Lcoin,$Lpref);
				# data
    foreach $obs ("in","out"){
	$tmp=$obs;$tmp=~tr/[a-z]/[A-Z]/;
	printf $fh 
	    "$txt%-8s |%8d %8d | %8d  | ",
	    "obs $tmp",$accmat{"$obs","in"},$accmat{"$obs","out"},$sum{"$obs","obs"};
				# random
	if ($Lcoin){printf $fh "%6.1f ",$ran{"$obs","coin"};}
	if ($Lpref){printf $fh "%6.1f ",$ran{"$obs","pref"};}
	if ($Lcoin||$Lpref){print $fh " | ";}
				# percentages
	printf $fh "%6.1f %6.1f  |\n",$q{"$obs","obs"},$q{"$obs","prd"}; 
    }
    &wrt_res_accmat_line($fh,$txt,$Lcoin,$Lpref);
				# sum prd
    printf $fh 
	"$txt%-8s |%8d %8d | %8d  | ","prd SUM",$sum{"in","prd"},$sum{"out","prd"},$sum{"obs"};
    if ($Lcoin) {printf $fh "%6.1f ",$ran{"q2","coin"};}    
    if ($Lpref) {printf $fh "%6.1f ",$ran{"q2","pref"};}if ($Lcoin||$Lpref){print $fh " | ";}
    printf $fh "%6.1f %6s  |\n",$q{"q2"},"<-Q2",$ran{"q2"};
    &wrt_res_accmat_line($fh,$txt,$Lcoin,$Lpref);
}				# end of wrt_res_accmat

#==========================================================================================
sub wrt_res_accmat_header {
    local ($fh,$txt,$Lcoin,$Lpref) = @_ ;
    print $fh "# Accuracy matrix:     (RnCoin: randomly flipping coin, RnPref: ratios) \n";
    printf $fh "$txt%8s   %8s %8s %8s   | "," "," ","Numbers"," ";
    if($Lcoin && $Lpref){printf $fh "%13s  | "," Random pred ";}
    elsif($Lcoin || $Lpref){printf $fh "%7s | ","Random";}
    printf $fh "%13s \n"," Percentages";
    printf $fh "$txt%8s +------------------+-----------+-"," ";
    if($Lcoin&&$Lpref){print $fh "---------------+";}elsif($Lcoin||$Lpref){printf $fh "--------+";}
    print $fh "----------------+\n";

    printf $fh "$txt%8s |%8s %8s | %8s  | "," ","prd IN","prd OUT","obs SUM";
    if($Lcoin){printf $fh "%6s ","RnCoin";}if($Lpref){printf $fh "%6s ","RnPref";}
    if($Lcoin||$Lpref){print $fh " | ";}
    printf $fh "%6s %6s  |\n","Q\%obs","Q\%prd";
}				# end of wrt_res_accmat_header

#==========================================================================================
sub wrt_res_accmat_line {
    local ($fh,$txt,$Lcoin,$Lpref) = @_ ;
    $tmp8="--------";$tmp6="------";
    printf $fh "$txt%8s-+%8s-%8s-+-%8s--+-",$tmp8,$tmp8,$tmp8,$tmp8;
    if($Lcoin){printf $fh "%6s-",$tmp6;}if($Lpref){printf $fh "%6s-",$tmp6;}
    if($Lcoin||$Lpref){print $fh "-+-";}
    printf $fh "%6s-%6s--+\n",$tmp6,$tmp6;
}				# end of wrt_res_accmat_line


#==========================================================================================
sub wrt_res_statprd {
    $[=1;
    local ($file_statprd,@fh) = @_ ;

    $ct=1;			# evaluate cumulative sums (starting from highest Nprd)
    while (defined $res{"$ct","sum"}){++$ct;}
    $max=$ct-1;
    $cum=$cumin=$cumout=0;
    foreach $ct(1..$max){
	$it=$max-$ct+1;		# invert counter from max -> 1
	$cum+=$res{"$it","sum"};$cumin+=$res{"$it","in"};$cumout+=$res{"$it","out"};
	$res{"$it","cum"}=$cum;$res{"$it","in","cum"}=$cumin;$res{"$it","out","cum"}=$cumout;}

    foreach $fh(@fh){
	if ($fh ne "STDOUT"){ &open_file($fh, ">$file_statprd");}
	print $fh 
	    "# Nprd        number of HTM predicted\n",
	    "# Sum         Sum of occurrences\n",
	    "# S_in/out    Sum for 'in'/'out'\n",
	    "# Scpin/out   Sum over proteins with both caps 'in','out'\n",
	    "# Cum         cumulative sum (starting from highest)\n",
	    "# C_in/out    cumulative for 'in'/'out'\n",
	    "# Nexcluded   $nexclNresMin (as shorter than $nresMin)\n";
	if (defined $nORF){
	    if ($nORF>1){
		print $fh 
		    "# Cum%        percentage cumulative (all ORF's =$nORF)\n";}}
	printf $fh 
	    "%3s\t%5s\t%5s\t%5s\t%5s\t%5s\t%5s\t%5s\t%5s",
	    "Nprd","Sum","S_in","S_out","Scpin","Scpout","Cum","C_in","C_out";
	if (($fh ne "STDOUT")&&(defined $nORF)&&($nORF>1)){
	    printf $fh "\t%5s\t%5s\t%5s\n","Cum%","C_in%","C_out%";}else {print $fh "\n";}
	    
	$ct=1;
	foreach $ct(1..$max){	# ini
	    $res_sum{"$ct","sum"}=$res_sum{"$ct","in"}=$res_sum{"$ct","out"}=0;
	    $res_sum{"$ct","cum"}=$res_sum{"$ct","in","cum"}=$res_sum{"$ct","out","cum"}=0;}
	$ct_caps_in=$ct_caps_out=0;
	foreach $ct(1..$max){	# print all
	    if (($ct/2)==int($ct/2)) {$Leven=1;}else{$Leven=0;}
	    if (! $Leven){$res{"$ct","caps_in"}=$res{"$ct","in"};
			  $res{"$ct","caps_out"}=$res{"$ct","out"};}
	    else{$res{"$ct","caps_in"}=$res{"$ct","caps_out"}=0;}
	    $ct_caps_in+=$res{"$ct","caps_in"};$ct_caps_out+=$res{"$ct","caps_out"};

	    printf $fh 
		"%3d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d",
		$ct,$res{"$ct","sum"},$res{"$ct","in"},$res{"$ct","out"},
		$res{"$ct","caps_in"},$res{"$ct","caps_out"},
		$res{"$ct","cum"},$res{"$ct","in","cum"},$res{"$ct","out","cum"};
	    if (($fh ne "STDOUT")&&(defined $nORF)&&($nORF>1)){
		printf $fh 
		    "\t%5d\t%5d\t%5d\n",(100*$res{"$ct","cum"}/($nORF-$nexclNresMin)),
		    (100*$res{"$ct","in","cum"}/($nORF-$nexclNresMin)),
		    (100*$res{"$ct","out","cum"}/($nORF-$nexclNresMin));}
	    else {print $fh "\n";}
				# compute sums
	    $res_sum{"$ct","sum"}+=$res{"$ct","sum"};$res_sum{"$ct","cum"}+=$res{"$ct","cum"};
	    $res_sum{"$ct","in"}+=$res{"$ct","in"};$res_sum{"$ct","out"}+=$res{"$ct","out"};
	    $res_sum{"$ct","in","cum"}+=$res{"$ct","in","cum"};
	    $res_sum{"$ct","out","cum"}+=$res{"$ct","out","cum"}; }
	printf $fh 
	    "%3s\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d",
	    "all",$res_sum{"$ct","sum"},$res_sum{"$ct","in"},$res_sum{"$ct","out"},
	    $ct_caps_in,$ct_caps_out,
	    $res_sum{"$ct","cum"},$res_sum{"$ct","in","cum"},$res_sum{"$ct","out","cum"};
	if (($fh ne "STDOUT")&&(defined $nORF)&&($nORF>1)){
	    printf $fh 
		"\t%5d\t%5d\t%5d\n",
		(100*$res_sum{"$ct","cum"}/($nORF-$nexclNresMin)),
		(100*$res_sum{"$ct","in","cum"}/($nORF-$nexclNresMin)),
		(100*$res_sum{"$ct","out","cum"}/($nORF-$nexclNresMin));}
	else {print $fh "\n";}
	    
	if ($fh ne "STDOUT"){ close($fh);}
    }
}				# end of wrt_res_statprd


