#!/usr/sbin/perl -w
#----------------------------------------------------------------------
# fssp_ide_ali
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	fssp_ide_ali.pl list of fssp files
#
# task:		extract seq from fssp which have certain features (e.g. %id>x)
# 		
#
#----------------------------------------------------------------------#
#	Burkhard Rost			July,	        1994           #
#			changed:		,      	1994           #
#			changed:	March	,      	1997           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


#------------------------------
# sets array count to start at 1, not at 0
#------------------------------
$[ =1 ;

$script_name      = "fssp_ide_ali";
$script_goal      = "extract alis for seq from fssp which have certain features (e.g. %id>x) returns also seq profile!";
$script_input     = "list of fssp files";
$script_opt_ar[1] = "cut_off lower seq_id, 2nd arg or: 'low=x'";
$script_opt_ar[2] = "cut_off upper seq_id, 3rd arg or: 'up='";
$script_opt_ar[3] = "cut_off low zscores , 4th arg or: 'zmin='";
$script_opt_ar[4] = "cut_off 2*Lali/L1+L2, 5th arg or: 'rlali='";
$script_opt_ar[5] = "file_constraint     , 6th arg or: 'file=' (ids, or dssp or any)".
    "\n--- \t \t means pairs if match id (2nd seq) found in file ";
$script_opt_ar[6] = "fileOut=x0 fileOutIdpairs=x1 fileOutOrphans=x2 \n--- \t \t (write only x0, x1, and x2)";
$script_opt_ar[7] = "doKing fileKing=x1  (separate kingdoms, \n--- \t \t file with 'pdbid\tswiss\tking')";
$script_opt_ar[8] = "verbose,verbose2";
$script_opt_ar[9] = "lmin= (minimal length)";

push (@INC, "/home/rost/perl") ;
# require "ctime.pl";  # require "rs_ut.pl" ; 
require "lib-ut.pl"; require "lib-br.pl";
# require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
@Date = split(' ',&ctime(time)) ; shift (@Date) ; 

#------------------------------
# number of arguments ok?
#------------------------------
if ($#ARGV < 1) {
    &myprt_line; &myprt_txt("perl script to $script_goal"); &myprt_empty;
    &myprt_txt("usage: \t $script_name $script_input"); &myprt_txt("optional:");
    for ($it=1; $it<=$#script_opt_ar; ++$it) {
	print"--- opt $it: \t $script_opt_ar[$it] \n"; }&myprt_empty; 
    exit;}

#----------------------------------------
# about script
#----------------------------------------
&myprt_line; &myprt_txt("perl script to $script_goal"); &myprt_empty;
&myprt_txt("usage: \t $script_name $script_input"); &myprt_txt("optional:");
for ($it=1; $it<=$#script_opt_ar; ++$it) {
    print"--- opt $it: \t $script_opt_ar[$it] \n"; 
} &myprt_empty; 

#----------------------------------------
# read input
#----------------------------------------
$file_in	= $ARGV[1]; 	

				# ini
$lower_seqide= 0;
$upper_seqide= 99;
$file_constr=  "unk";
$rlali_min=    0.0;		# minimal ratio: (2*Lali)/(L1+L2)
$z_min=        0.0;		# minimal zscore
$len_min=20;			# minimal length of hits accepted
				# read other input arguments
$LsomeOut=0;
$LdoKing=1;			# separate kingdoms
$LdoKing=0;			# separate kingdoms
$fileKing=     "/home/rost/pub/data/seqUniq849-kingdom.list";

$Lscreen=      0;
$Lscreen2=     0;

shift @ARGV;
foreach $arg ( @ARGV ){
    print "--- digesting arg '$arg'\n"; 
    if    ($arg=~/low=/) {$lower_seqide=$arg;$lower_seqide=~s/low=//g;}
    elsif ($arg=~/up=/)  {$upper_seqide=$arg;$upper_seqide=~s/up=//g;}
    elsif ($arg=~/file=/){$file_constr=$arg;$file_constr=~s/file=//g;}
    elsif ($arg=~/zmin=/){$tmp=$arg;$tmp=~s/^zmin=|\s//g;$z_min=$tmp;}
    elsif ($arg=~/rlali=/){$tmp=$arg;$tmp=~s/^rlali=|\s//g;$rlali_min=$tmp;}
    elsif ($arg=~/lmin=/){$tmp=$arg;$tmp=~s/^lmin=|\s//g;$len_min=$tmp;}
    elsif ($arg=~/doKing/){$LdoKing=1;}
    elsif ($arg=~/doKing=/){$tmp=$arg;$tmp=~s/^.*=|\s//g;$LdoKing=$tmp;}
    elsif ($arg=~/fileKing=/){$tmp=$arg;$tmp=~s/^.*=|\s//g;$fileKing=$tmp;}
    elsif ($arg=~/^notScreen2/){$Lscreen2=0;}
    elsif ($arg=~/^notScreen/) {$Lscreen=0;}
    elsif ($arg=~/^verbose2/)  {$Lscreen2=1;}
    elsif ($arg=~/^verbose/)   {$Lscreen=1;}
    elsif ($arg=~/^fileOut/){
	$LsomeOut=1;
	if    ($arg=~/^fileOutIdpairs=/){$arg=~s/^.*=//g;$fileOut{"idpairs"}=$arg;}
	elsif ($arg=~/^fileOutOrphans=/){$arg=~s/^.*=//g;$fileOut{"orphans"}=$arg;}
	elsif ($arg=~/^fileOut=/)       {$arg=~s/^.*=//g;$fileOut=$arg;}}
    else { print "*** fssp_ide_ali: unrecognised argument '$arg'\n";
	   die;}}

&myprt_txt("file in: \t \t  \t $file_in"); 
&myprt_txt("lower seqide:     \t \t $lower_seqide");
&myprt_txt("upper seqide:     \t \t $upper_seqide");
if ($z_min>0)             {&myprt_txt("minimal zscore:  \t \t $z_min");}
if ($rlali_min>0)         {&myprt_txt("minimal (2*Lali/L1+L2):  \t $rlali_min");}
if ($file_constr ne "unk"){&myprt_txt("constraint search:\t \t $file_constr");}

#------------------------------
# defaults
#------------------------------

$file_metric="/home/rost/pub/topits/mat/Maxhom_McLachlan.metric";
#$file_metric="/home/rost/pub/topits/Maxhom_Blosum.metric";

$scale=10;			# determines grid for histogram
$scale=1;			# determines grid for histogram

$Lread_alis=1;			# take seqide from FSSP table, or recompile (weighted)?
$dir_fssp="/data/fssp/"; $ext_fssp="_dali.fssp";
$Lheader=1;
@des=("NR","IDE","LALI","LSEQ2","Z","STRID1","STRID2","RMSD");

$tmp=$file_in;$tmp=~s/.*\///g;
if (! defined $fileOut){
    $tmp=~s/fssp//g;
    $fileOut="Out-"."$tmp"; $fileOut=~s/\.list//g; 
    $fileOut.="-"."$lower_seqide"."-"."$upper_seqide"; 
    if ($z_min>0){ $tmp=int(10*$z_min)/10;$fileOut.="-Z"."$tmp";}
    if ($rlali_min>0.1){ 
	foreach $add (0.9,0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1){
	    if($rlali_min>$add){last;}}
	$fileOut.="-R"."$add";}}

@des_fileOut=("gr","grdet","histide","histwide","histwnide","histocc","idok","idnot",
	       "idpairs","idpairs2","orphans");

if ($LsomeOut){$#tmp=0;
	       foreach $des(@des_fileOut){if (defined $fileOut{"$des"}){push(@tmp,$des);}}
	       @des_fileOut=@tmp;}
else {
    if ($fileOut !~/\.[^._-]+$/){$fileOut.=".c";}
    $fileOut=~s/\-\-/\-/g;
    $fileOut{"gr"}=       $fileOut; $fileOut{"gr"}       =~s/Out/Gr/;
    $fileOut{"grdet"}=    $fileOut; $fileOut{"grdet"}    =~s/Out/Grdet/;
    $fileOut{"histide"}=  $fileOut; $fileOut{"histide"}  =~s/Out/HisIde/;
    $fileOut{"histwide"}= $fileOut; $fileOut{"histwide"} =~s/Out/HisWide/;
    $fileOut{"histwnide"}=$fileOut; $fileOut{"histwnide"}=~s/Out/HisWnide/;
    $fileOut{"histocc"}=  $fileOut; $fileOut{"histocc"}  =~s/Out/HisOcc/;
    $fileOut{"idok"}=     $fileOut; $fileOut{"idok"}     =~s/Out/OutOk/;
    $fileOut{"idnot"}=    $fileOut; $fileOut{"idnot"}    =~s/Out/OutNot/;
    $fileOut{"exchange"}= $fileOut; $fileOut{"exchange"} =~s/Out/Exch/;
    $fileOut{"idpairs"}=  $fileOut; $fileOut{"idpairs"}  =~s/^Out/Id/;
    $fileOut{"idpairs2"}= $fileOut; $fileOut{"idpairs2"} =~s/^Out/Id2/;
    $fileOut{"orphans"}=  $fileOut; $fileOut{"orphans"}  =~s/^Out/Orph/;
    foreach $des ("orphans","idpairs","idpairs2"){
	$fileOut{"$des"}=~s/\.c$/\.list/;}}

# print "xx files=\n";foreach $des (@des_fileOut){print "xx des=$des, write '",$fileOut{"$des"},"'\n";}exit;

$fhout="FHOUT";$fhoutgr="FHOUT_GR";$fhoutgrdet="FHOUT_GRDET";
$fhhist="FHOUT_HIST";$fhhistocc="FHOUT_HISTOCC";
$fhidok="FHOUT_IDOK";$fhidnot="FHOUT_IDNOT";
$fhin="FHIN";
$fhin_constr="FHIN_CONSTR";$fhout_exchange="FHOUT_EXCHANGE";
$fhout_orphans="FHOUT_ORPHANS";

&myprt_empty;

#------------------------------
# check existence of file
#------------------------------
if (! -e $file_in) {&myprt_empty; &myprt_txt("ERROR:\t file $file_in does not exist"); 
		    exit; }
#----------------------------------------
# read list
#----------------------------------------
$fileOutSave=$fileOut;
&open_file("$fhout", ">$fileOut");
if (defined $fileOut{"gr"}) {
    $file=$fileOut{"gr"}; &open_file("$fhoutgr", ">$file");}
if ($Lread_alis && (defined $fileOut{"grdet"}) ){
    $file=$fileOut{"grdet"}; &open_file("$fhoutgrdet", ">$file");
    print $fhoutgrdet "# weighting metric: $file_metric\n";
    printf 
	$fhoutgrdet 
	    "%-6s\t%-6s\t%5s\t%5s\t%6s\t%6s\t%6s\n",
	    "id1","id2","side","len","\%ide","\%wnide","wide";}
$#id_constr=0;			# read the constraints
if (-e $file_constr){ &open_file("$fhin_constr", "$file_constr");
		      while(<$fhin_constr>){
			  $_=~s/\n|\s//g;if (length($_)<1){next;}$_=~s/.*\/|\..*//g;
			  push(@id_constr,$_);}close($fhin_constr);}

foreach $i ($lower_seqide..$upper_seqide){ # initialise histogram counts
    $histo{$i}=0;
    foreach $king("euka","proka","archae","eu-pro"){$histo{"$i","$king"}=0;}}
$ctprot=0; $ctprotok=0; $cthits=0;

$#file_fssp=0;
if (! &is_fssp($file_in) ) {
    &open_file("FILE_INLIST", "$file_in");
    while ( <FILE_INLIST> ) {
	$tmp=$_;$tmp=~s/\s|\n//g;
	if (length($tmp)>1) {
	    if (length($tmp)==4)    {$file_infssp="$dir_fssp"."$tmp"."$ext_fssp"; }
	    elsif (length($tmp)==5) {$file_infssp="$dir_fssp"."$tmp"."$ext_fssp"; }
	    elsif ($tmp=~/^\/data/) {$file_infssp=$tmp; }
	    else {print "*** ERROR: length wrong for:$tmp|\n"; 
		  exit; }
	    if (-e $file_infssp) {
		push(@file_fssp,$file_infssp); } }} close(FILE_INLIST); }
else {
    push(@file_fssp,$file_in); }
				# ------------------------------
				# read kingdom
				# ------------------------------
&open_file("$fhin", "$fileKing");$ct=0;
while(<$fhin>){$_=~s/\n//g;
	       if (/^\#/){next;} # ignore RDB header
	       ++$ct;
	       if ($ct<3){next;} # ignore RDB names/formats
	       @tmp=split(/\t/,$_);
	       $tmp[1]=~s/\s//g;$tmp[3]=~s/\s//g;
	       $king{"$tmp[1]"}=$tmp[3];}close($fhin);

				# ----------------------------------------
				# initialise the metric /profile stuff
				# ----------------------------------------
if ($Lscreen){ print "metric=$file_metric, read=$Lread_alis,\n"; }
if ( (-e $file_metric) && ($Lread_alis) ){
    $string_aa= &metric_ini;	# aa's: = "VLIMFWYGAPSTCHRKQENDBZ"
				# read metric
    %metric=    &metric_rd($file_metric);
				# find min/max
    $#key=$metric_min=$metric_max=0; 
    @key=keys %metric;
    foreach $key(@key){if    ($metric{$key} > $metric_max){$metric_max=$metric{$key};}
		       elsif ($metric{$key} < $metric_min){$metric_min=$metric{$key};} }
    $metric_intervall=($metric_max-$metric_min)/100;
				# normalise metric (0-1)
    %metricnorm=&metric_norm_minmax(0,1,$string_aa,%metric);
}
				# ------------------------------
				# for exchange matrix
$#array_aa=0;@array_aa=split(//,$string_aa);
foreach $aa1(@array_aa,"sum"){	# ini exchange metric
    foreach $aa2(@array_aa,"sum"){
	$exchange{"$aa1","$aa2"}=0;}}
				# --------------------------------------------------
				# now for entire list
				# --------------------------------------------------
if (defined $fileOut{"orphans"}) {
    $fileOut=$fileOut{"orphans"}; # file to write orphans (no hit found)
    &open_file("$fhout_orphans", ">$fileOut"); }

$#idrd=$#idok=$#idnot=$#sumint_ide=$#sum_wide=$#sumint_wnide=0;%flag=0;
foreach $file_infssp(@file_fssp) {
    ++$ctprot;
    $tmpid=$file_infssp;$tmpid=~s/.*\/|\.fssp.*//g;$id1=$tmpid;
    push(@idrd,$tmpid);$idPairs{"$tmpid"}="";
    if ($Lscreen){printf "file:%-28s seq id > %3d for:\n",$file_infssp, $lower_seqide;}
    print $fhout "file:$file_infssp\n";
				# ----------------------------------------
				# reading one file
    $#posok=$#arprint=0;
    &open_file("FILE_INFSSP", "$file_infssp");

    while ( <FILE_INFSSP> ) { 
	last if (/^\#\# PROTEINS|^\#\# SUMMARY/); 
				# length of search sequence
	if (/^SEQLENGTH/){$len1=$_;$len1=~s/^SEQLENGTH\s+//g;$len1=~s/\s|\n//g;}}
    $#arprint=0;
    $Lnot_orphans=0;
    while ( <FILE_INFSSP> ) {
	$_=~s/^\s*//g;
	if ( (length($_)<2) || (/^\#\# ALI/) ) {$tmpline=$_;
						last;}
				# read header
	if ( (/^NR\./) && ($Lheader) ) { 
	    $tmp1=substr($_,1,66); 
	    push(@arprint,$tmp1);
	    $#tmp=0;@tmp=split(/\s+/,$_);$it=0;
	    foreach $tmp (@tmp){++$it;
				foreach $des (@des) {
				    if ($tmp =~ /$des/) { $pos{"$des"}=$it; 
							  last; }}}
	    if ($cthits==0){if (defined $fileOut{"gr"}) {
		foreach$des(@des){if($des eq $des[$#des]){print $fhoutgr "$des\n";}
				  else {                  print $fhoutgr "$des\t";}}} }}
				# read protein info in header
	else {
	    @tmp=split(/\s+/,$_);
	    foreach $des (@des) {$tmp=$pos{"$des"};
				 $rd{"$des"}=$tmp[$tmp];$rd{"$des"}=~s/\s|://g;}
	    $flag=0;
	    if ( ($rd{"IDE"}>=$lower_seqide)&&($rd{"IDE"}<=$upper_seqide) ) {$flag=1;}
#	    print "x.x z=",$rd{"Z"},", l1=$len1, lali=",$rd{"LALI"},", l2=",$rd{"LSEQ2"},",\n";
	    $rlali=(2*$rd{"LALI"})/($len1+$rd{"LSEQ2"});
	    if ( $rd{"Z"}<$z_min )   {$flag=0;}
	    if ( $rlali<$rlali_min ) {$flag=0;}
				# check list of to-be-excluded
	    if ($flag && ($#id_constr>0)) {
		$flag=0;
		foreach $id_constr(@id_constr){$tmpid2=substr($rd{"STRID2"},1,4);
					       if ($id_constr=~/$tmpid2/){$flag=1;
									  last;}}}
	    if ($flag) {	# exclude identical PDBids
		$tmpid2=substr($rd{"STRID2"},1,4);
		if (substr($tmpid,2,3) =~ substr($tmpid2,2,3)){$flag=0;}}
	    if ($flag && ($len_min>0)) { # exclude too short?
		if ($rd{"LALI"}<$len_min){$flag=0;}}
	    if (! $flag) {
		next;}
	    push(@posok,$rd{"NR"}); # add position to list
	    if (!defined $flag{"$tmpid"}){++$ctprotok;$Lnot_orphans=1;
					  $histocc{$tmpid}=0; # initialise histo of Noccurrence
					  push(@idok,$tmpid);$flag{"$tmpid"}=1;}
	    $tmp1=substr($_,1,66); 
	    $tmpx=$rd{"STRID2"};$tmpx=~s/-/_/g; # fssp notation 1pdb-C to 1pdb_C
	    $id2=$tmpx;
	    $idPairs{"$tmpid"}.=$tmpx.",";
	    push(@arprint,$tmp1);
	    if (defined $fileOut{"gr"}) {
		foreach$des(@des){if($des eq $des[$#des]){print $fhoutgr $rd{"$des"},"\n";}
				  else {                  print $fhoutgr $rd{"$des"},"\t";}}}
	    ++$cthits;
	    $id1NoChain=substr($id1,1,4);$id2NoChain=substr($id2,1,4);
	    if (! $Lread_alis) {
		push(@sumint_ide,(100*$rd{"IDE"}));
		$tmp=$scale*$rd{"IDE"}; # note: perc * 10 for finer scaling in histogram
		++$histo{$tmp};
		if ($LdoKing){	# check kingdom
		    if ((defined $king{"$id1NoChain"}) && (defined $king{"$id2NoChain"})){
			if    (($king{"$id1NoChain"} eq $king{"$id2NoChain"})){
			    $king=$king{"$id1NoChain"};++$histo{"$tmp","$king"};}
			elsif (($king{"$id1NoChain"}=~/^proka|^euka/)&&
			       ($king{"$id2NoChain"}=~/^proka|^euka/)){
			    ++$histo{"$tmp","eu-pro"};}}}}
	    ++$histocc{$tmpid}; }}
				# ----------------------------------------
				# read alignments
    if ($Lread_alis) {
	if ($tmpline =~ /\#/){$line_ali="$tmpline"."\n";}else {$line_ali="";}
	while ( <FILE_INFSSP> ) { # read all alis into @line_ali
	    last if ( /^\#\# EQUI/ );
	    $line_ali.="$_"; }
	%rd_ali=0;
	%rd_ali=&fssp_rd_ali($line_ali,@posok);
				# ------------------------------
				# analyse sequence identity
	$seq1=$rd_ali{"seq1"};
	foreach $pos(@posok){
	    $seq2=$rd_ali{"seq2","$pos"};
	    ($ide,$len)=   &seqide_compute ($seq1,$seq2);
	    %exchange_loc= &seqide_exchange($seq1,$seq2,$string_aa);
	    &get_sum_exchange(%exchange_loc);
	    ($wide,$len2)= &seqide_weighted($seq1,$seq2,%metric);
	    ($wnide,$len2)=&seqide_weighted($seq1,$seq2,%metricnorm);
	    if ($len>0){
		$ide_perc=$ide/$len;
		push(@sumint_ide,int(100*$scale*$ide_perc));
		$tmp=int(100*$scale*$ide_perc);
		++$histo{$tmp}; # 
		if ($LdoKing){	# check kingdom
		    if ((defined $king{"$id1NoChain"}) && (defined $king{"$id2NoChain"})){
			if    (($king{"$id1NoChain"} eq $king{"$id2NoChain"})){
			    $king=$king{"$id1NoChain"};++$histo{"$tmp","$king"};}
			elsif (($king{"$id1NoChain"}=~/^proka|^euka/)&&
			       ($king{"$id2NoChain"}=~/^proka|^euka/)){
			    ++$histo{"$tmp","eu-pro"};}}}}
	    if ($len2>0){
		$wide_perc=$wide/$len2;$wnide_perc=$wnide/$len2;
		push(@sum_wide,$wide_perc);push(@sumint_wnide,int($scale*100*$wnide_perc));
		$tmp=int($scale*100*$wnide_perc);++$histo_wnide{$tmp};
		$ct=$metric_min;
		while ($ct < $metric_max){
		    if ( ($wide_perc>=$ct) && ($wide_perc<=($ct+$metric_intervall)) ) {
			++$histo_wide{$ct};  last; }
		    $ct+=$metric_intervall; } }
	    if ( ($len>0)&& ($len2>0) ){
		if (defined $fileOut{"grdet"}) {
		    $id1=~s/[-_]//g;$id2=~s/[-_]//g;
		    printf $fhoutgrdet 
			"%-6s\t%-6s\t%5d\t%5d\t%6.1f\t%6.1f\t%6.1f\n",
			$id1,$id2,$ide,$len,(100*$ide_perc),(100*$wnide_perc),$wide_perc; }}}
	%rd_ali=0; }
				# end of reading alignments
				# ----------------------------------------
    close(FILE_INFSSP);
    if (! $Lnot_orphans){
	print $fhout_orphans "$file_infssp\n";}
				# end of reading one file
				# ----------------------------------------
    if (!defined $flag{"$tmpid"}||(! $flag{"$tmpid"})){push(@idnot,$tmpid);}
#       ------------------------------
#       print
#       ------------------------------
    if ($#arprint >1) {
	foreach $i (@arprint) { if ($Lscreen2){print "$i\n";}
				print $fhout "$i\n";} }
}
close($fhout_orphans);
				# ------------------------------
				# exchange matrix
                                # ------------------------------
&wrt_exchange("%3d"," ","STDOUT",%exchange);
if (defined $fileOut{"exchange"}) {
    $file=$fileOut{"exchange"};&open_file("$fhout_exchange", ">$file");
    &wrt_exchange("%5d","\t",$fhout_exchange,%exchange);
    close($fhout_exchange); }

@fh=("$fhout");
foreach $fh (@fh){
    print $fh 
	"# statistics: \%sequence ide=($lower_seqide-$upper_seqide), ",
	"zDali>$z_min, (2*Lali/L1+L2)> $rlali_min\n";
    print $fh "# number of proteins searched:   $ctprot\n";
    print $fh "# number of proteins with hits:  $ctprotok\n";
    print $fh "# number of hits found in total: $cthits\n";}
close(FILE_INLIST); close($fhout); 

if (defined $fileOut{"gr"}) {close($fhoutgr); }
if ($Lread_alis && (defined $fileOut{"grdet"}) ) {close($fhoutgrdet);}

				# sequence identity
$sum=0;foreach $_(@sumint_ide){$sum+=$_;}

if (defined $fileOut{"histide"}) {
    $file=$fileOut{"histide"}; &open_file("$fhhist", ">$file");
    if (($#sumint_ide*$scale)>0){$tmp=($sum/($#sumint_ide*$scale));}else{$tmp=0;}
    printf $fhhist "# average over %9d proteins =%6.2f\n",$#sumint_ide,$tmp;
    if ($LdoKing){
	printf $fhhist 
	    "%4s\t%-10s\t%-10s\t%-10s\t%-10s\n","\%ide","number of pairs","euka","proka","eu-pro";}
    else {
	printf $fhhist "%4s\t%10s\n","\%ide","number of pairs";}
    foreach $i (($scale*$lower_seqide)..($scale*$upper_seqide)){
	if ( (defined $histo{$i}) && ($histo{$i}>0) ){
	    printf $fhhist "%5.1f\t%10d",($i/$scale),$histo{$i}; 
	    if ($LdoKing){printf $fhhist 
			      "\t%10d\t%10d\t%10d",
			      $histo{"$i","euka"},$histo{"$i","proka"},$histo{"$i","eu-pro"};}
	    printf $fhhist "\n";}}close($fhhist);}


if ($Lread_alis ){
    if (defined $fileOut{"histwnide"}) { # weighted similarity
	$sum=0;foreach $_(@sumint_wnide){$sum+=$_;}
	$file=$fileOut{"histwnide"}; &open_file("$fhhist", ">$file");
	print $fhhist  "# metric:    $file_metric\n";
	print $fhhist  "# \%wnide     weighted similarity (normalised 0-1)\n";
	printf 
	    $fhhist "# average    %6.2f (over %9d proteins)\n",
	    $#sumint_wnide,($sum/($#sumint_wnide*$scale));
	printf $fhhist "%6s\t%10s\n","\%wnide","number of pairs";
	foreach $i (0..($scale*100)){
	    if ( (defined $histo_wnide{$i}) && ($histo_wnide{$i}>0) ){
		printf $fhhist "%6.1f\t%10d\n",($i/$scale),$histo_wnide{$i}; }}
	close($fhhist); }

    if (defined $fileOut{"histwide"}) { #  similarity
	$sum=0;foreach $_(@sum_wide){$sum+=$_;}
	$file=$fileOut{"histwide"}; &open_file("$fhhist", ">$file");
	print $fhhist  "# metric:    $file_metric\n";
	print $fhhist  "# \%wide      weighted similarity\n";
	printf $fhhist "# average    %6.2f (over %9d proteins)\n",$sum/$#sum_wide,$#sum_wide;
	printf $fhhist "%6s\t%10s\n","\%wide","number of pairs";
	$ct=$metric_min;
	while ($ct < $metric_max){
	    if ( (defined $histo_wide{$ct}) && ($histo_wide{$ct}>0) ) {
		printf $fhhist "%6.1f\t%10d\n",$ct,$histo_wide{$ct};}
	    $ct+=$metric_intervall; }
	close($fhhist);}
}				# end of weighted

if (defined $fileOut{"histocc"}) {
    $file=$fileOut{"histocc"}; &open_file("$fhhistocc", ">$file");
    printf $fhhistocc "%4s\t%-10s\t%5s","no","id guide","N found";
    if ($#id_constr>0){printf $fhhistocc "\t%7s\n","pchance";}else{printf $fhhistocc "\n";}
    $ct=$ctran=$pran=0;
    foreach $it (1..$#idok){
	$id1=$idok[$it];
	printf $fhhistocc "%4d\t%-10s\t%5d","$it",$id1,$histocc{$id1}; 
	if ($#id_constr>0){		# compute likelihood
	    $pran=$histocc{$id1}/$#id_constr;
	    printf $fhhistocc "\t%7.4f\n",$pran;}
	else{printf $fhhistocc "\n";}

	$ct+=$histocc{$id1};
	$ctran+=$pran; }
    $it=$#idok;
    printf $fhhistocc "%4d\t%-10s\t%5d","$it","sum",$ct;
				# probability
    if ($#id_constr>0){
	printf $fhhistocc "\t%7.4f\n",($ctran/$it);}else{printf $fhhistocc "\n";}
    close($fhhistocc);}

if (defined $fileOut{"idok"}) {
    $file=$fileOut{"idok"};  &open_file("$fhidok", ">$file");
    print "--- id's of files with hits: \n";
    foreach$id(@idok){print $fhidok "$id\n";
		      print "$id, ";}print"\n";close($fhidok);}
if (defined $fileOut{""}) {
    $file=$fileOut{"idnot"}; &open_file("$fhidnot", ">$file");
    print "--- id's of files with no hits: \n";
    foreach$id(@idnot){print $fhidnot "$id\n";
		       print "$id, ";}print"\n";close($fhidnot);}
				# write identifiers
if (defined $fileOut{"idpairs"}) {
    $file=$fileOut{"idpairs"};&open_file("$fhout", ">$file");
    foreach $id(@idok){print $fhout "$id\t",$idPairs{"$id"},"\n";}close($fhout);}
if (defined $fileOut{"idpairs2"}) {
    $file=$fileOut{"idpairs2"};&open_file("$fhout", ">$file");
    foreach $id(@idok){
	print $fhout "$id\n"; $idPairs{"$id"}=~s/,$//g;@tmp=split(/,/,$idPairs{"$id"});
	foreach $id2(@tmp){print $fhout "$id2\n";}}close($fhout);}

print "--- find output in files:\n--- \t";
foreach $des (@des_fileOut) { 
    if ((! defined $fileOut{"$des"})||(! -e$fileOut{"$des"})){ 
	next; }
    print " ",$fileOut{"$des"},",";} print"$fileOutSave\n";

exit;

#==========================================================================================
sub get_sum_exchange {
    local (%ex_in) = @_ ;
    local ($aa1,$aa2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    get_sum_exchange  sums the values for the (GLOBAL) array %exchange
#                      also global: @array_aa
#--------------------------------------------------------------------------------
    foreach $aa1(@array_aa){
	foreach $aa2(@array_aa){
	    $exchange{"$aa1","$aa2"}+=$ex_in{"$aa1","$aa2"}; }}
}				# end of get_sum_exchange

#==========================================================================================
sub wrt_exchange {
    local ($form,$sep,$fhout,%ex_in) = @_ ;
    local ($form2,$aa1,$aa2);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_sum_exchange  sums the values for the (GLOBAL) array %exchange
#                      also global: @array_aa
#--------------------------------------------------------------------------------
    $form2=$form;$form2=~s/\.\d*|d|f/s/g;
				# compute averages
    $ex_in{"sum","sum"}=0;
    foreach $aa1(@array_aa){
	$ex_in{"$aa1","sum"}=0;
	$ex_in{"sum","$aa1"}=0;
	foreach $aa2(@array_aa,"sum"){
	    $ex_in{"$aa1","sum"}+=$ex_in{"$aa1","$aa2"};
	    $ex_in{"sum","$aa1"}+=$ex_in{"$aa2","$aa1"};
	}
	$ex_in{"$aa1","sum"}=$ex_in{"$aa1","sum"}/2;
	$ex_in{"sum","$aa1"}=$ex_in{"sum","$aa1"}/2;
	$ex_in{"sum","sum"}+=$ex_in{"$aa1","sum"};
    }
    $ex_in{"sum","sum"}=$ex_in{"sum","sum"}/2;
    
    printf $fhout "%3s$sep","AA=";
    foreach $aa1(@array_aa,"sum"){printf $fhout "$form2$sep",$aa1;}print $fhout "\n";
    foreach $aa1(@array_aa,"sum"){
	printf $fhout "%3s$sep",$aa1;
	foreach $aa2(@array_aa,"sum"){
	    printf $fhout "$form$sep",$ex_in{"$aa1","$aa2"}; }
	print $fhout "\n"; }
}				# end of wrt_sum_exchange

