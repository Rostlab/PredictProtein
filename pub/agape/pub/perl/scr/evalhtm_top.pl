#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="in: list of PHDhtm RDB files, out: segment accuracy\n".
    "     \t \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2000	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://www.columbia.edu/~rost/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	May,    	2000	       #
#------------------------------------------------------------------------------#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;
				# ------------------------------
if ($#ARGV<1){			# help
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName phd.rdb (or list)'\n";
    print  "      ------------------------------\n";
    print  "      \n";
    print  "      FOR GENOMES\n";
    print  "      \n";
    print  "      \n";
    print  "      'prd' will extract information about prediction only\n";
    print  "      nresMin=x  (skip proteins shorter than x)\n";
    print  "      fileNali=x (reads ids with NALIGN - as grepped == HACK!!)\n";
    print  "      nORF=x     (number of all ORF's, for percentages)\n";
    print  "      \n";
    print  "      \n";
    print  "      ------------------------------\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut", "x",       "name of output file";
    printf "%5s %-15s=%-20s %-s\n","","dirOut",  "x",       "directory of output files";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";

    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";

    printf "%5s %-15s %-20s %-s\n","","fil", "no value","";
    printf "%5s %-15s %-20s %-s\n","","ref", "no value","";
    printf "%5s %-15s %-20s %-s\n","","ref2", "no value","";


    printf "%5s %-15s %-20s %-s\n","","c11",   "no value",   "also compile segment overlap center prd obs within 11 res (ikeda)";
    printf "%5s %-15s %-20s %-s\n","","9",     "no value",   "also compile segment overlap 9 residues";

    printf "%5s %-15s %-20s %-s\n","","loop",  "no value",   "also compile accuracy for short loops";

    printf "%5s %-15s %-20s %-s\n","","loop",  "no value",   "also compile accuracy for short loops";
    printf "%5s %-15s %-20s %-s\n","","helix", "no value",   "also compile accuracy for long helices";
    printf "%5s %-15s %-20s %-s\n","","short", "no value",   "also compile accuracy for short loops";
    printf "%5s %-15s %-20s %-s\n","","long",  "no value",   "also compile accuracy for long helices";
    
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";



    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd} || length($par{$kwd})<1 );
	    if    ($par{$kwd}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    elsif ($par{$kwd}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-20s %-s\n","",$kwd,$par{$kwd},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);

    }
    exit;}
				# initialise variables
$fh=             "FHOUT";
$Lscreen=        1;
$LisList=0;
$#fileIn=0;

#------------------------------
# defaults
#------------------------------

$opt_phd=  "unk";
$opt=      "ref";
$opt_phd=  "htm";
$Lprd_only=0;

$nresMin=          5;
$nexclNresMin=     0;		# number of proteins excluded as too short

				# segment counted as correct if:
$par{"LsegC11"}=   0;		#  - ABS(center(obs)-center(prd))<= 11 residues
$par{"Lseg9"}=     0;		#  - pred and obs overlap 9 residues
$par{"Lseg3"}=     1;		#  - pred and obs overlap 3 residues
$par{"noverlap3"}= 3;		# number of residues required to overlap for score '3'
$par{"noverlap9"}= 9;		# number of residues required to overlap for score '9'

$par{"LsegC11"}=   1;		#  - ABS(center(obs)-center(prd))<= 11 residues
$par{"Lseg9"}=     1;		#  - pred and obs overlap 9 residues

$par{"LshortLoop"}=    0;       # 1|0: also compile performance for short loops
$par{"NshortLoopMin"}= 3;	# bin all loops less than this (3)
$par{"NshortLoopMax"}=10;	# bin all loops longer than this (10)
$par{"LlongHelix"}=    0;       # 1|0: also compile performance for long helices
$par{"NlongHelixMinOverlap"}= 9;	# minimal overlap for long helices
$par{"NlongHelixMaxLen"}=40;	# maximal number of residues in tm helix

				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/)        { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/)         { $dirOut=         $1; 
					    $dirOut.=        "/" if ($dirOut !~/\/$/);}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;
					    $Lscreen=        1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;
					    $Lscreen=        0;}
    elsif ($arg=~/^(is)?list$/i)          { $LisList=        1;}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
    elsif (-e $arg)                       { push(@fileIn,$arg); 
					    $LisList=        1 if ($arg=~/\.list/);}
#    elsif ($arg=~/^htm/)                  { $opt_phd=        "htm";}
#    elsif ($arg=~/^sec/)                  { $opt_phd=        "sec";}
#    elsif ($arg=~/^acc/)                  { $opt_phd=        "acc";}
#    elsif ($arg=~/^both/)                 { $opt_phd=        "both";}

    elsif ($arg=~/^nresMin=(.*)$/i)        { $nresMin=        $1;}
    elsif ($arg=~/^fileNali=(.*)$/i)       { $fileNali=       $1;}
    elsif ($arg=~/^nORF=(.*)$/i)           { $nORF=           $1;}

    elsif ($arg=~/^prd/)                   { $Lprd_only=      1;}

    elsif ($arg=~/^top/)                   { $opt=            "top";}
    elsif ($arg=~/^nof/)                   { $opt=            "nof";}
    elsif ($arg=~/^fil/)                   { $opt=            "fil";}
    elsif ($arg=~/^ref2/)                  { $opt=            "ref2";}
    elsif ($arg=~/^ref/)                   { $opt=            "ref";}

    elsif ($arg=~/^c11$/i)                 { $par{"LsegC11"}=   1;}
    elsif ($arg=~/^9$/)                    { $par{"Lseg9"}=     1;}

    elsif ($arg=~/^(loop|short)$/i)        { $par{"LshortLoop"}=1;}
    elsif ($arg=~/^(long|helix)$/i)        { $par{"LlongHelix"}=1;}

    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$fileIn=$fileIn[1];
die ("missing input $fileIn\n") if (! -e $fileIn);
if (! defined $fileOut){
    $tmp=$fileIn;$tmp=~s/^.*\///g;$fileOut="Out-".$tmp;}



if ($fileOut eq "unk") {
    $tmp=$fileIn;$tmp=~s/\.rdb.*$|\.list.*$//g;
    $fileOut="Top-"."$tmp".".dat";
    if ($nresMin>10){
	$tmp="-excl".$nresMin;
	$fileOut=~s/\.dat/$tmp\.dat/;}}

$fileOut_det= $fileOut;$fileOut_det=~s/_ana/_det/; $fileOut_det=~s/^Top-/Topdet-/;
$fileOut_det2=$fileOut;$fileOut_det2=~s/_ana/_det/;$fileOut_det2=~s/^Top-/Topdet2-/;
$fileOut_statprd=$fileOut;$fileOut_statprd=~s/_ana/_det/;$fileOut_statprd=~s/^Top-/Topstat-/;
$fileOut_protprd=$fileOut_statprd;$fileOut_protprd=~s/Topstat-/Topprot-/;
$fhin=           "FHIN";$fhout2="FHOUT2";$fhout3="FHOUT3";$fhoutProt="FHOUT_PROT";
$fh=             "FHOUT";

$file_names="/home/rost/mis/proj/htm/data/swiss/setall-names.dat";


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

@des_res=("Nok","Nobs","Nprd","Pok","Poks",
	  "Nok9","NPok9",
	  "NokC11","NPokC11",
	  "Ri","RiD"
	  );

$symh=           "H";		# symbol for HTM
$syml=           " ";		# symbol for HTM
$des_aa=         $des_out[1];
$des_obs=        $des_out[2];
$des_prd=        $des_out[3];
if ($Lprd_only) { $des_prd=$des_out[2];}

$des_Nok=        $des_res[1];	# key for number of correctly predicted
$des_Nobs=       $des_res[2];	# key for number of observed helices
$des_Nprd=       $des_res[3];	# key for number of predicted helices
$des_Nprd2=      "Nprd2";	# key for number of predicted helices for 2nd best model
$des_Pok=        $des_res[4];	# key for number of proteins correctly predicted
				# correct number of helices(100%)
$des_Poks=       $des_res[5];	# key for number of proteins correctly predicted
				# if more HTM are allowed to be predicted in end

$des_Nok9=       $des_res[6];	# key for number correct (overlap 9)
$des_NPok9=      $des_res[7];	# key for percentage of proteins with correct helix (overlap 9)
#$des_NPoks9=     $des_res[8];	# key for percentage of proteins with correct number wrong succession

$des_NokC11=     $des_res[8];	# key for number correct (overlap centers >=11, ikeda)
$des_NPokC11=    $des_res[9];	# key for percentage of proteins with correct helix (overlap center)
#$des_NPoksC11=   $des_res[11];	# key for percentage of proteins with correct number wrong succession




#$des_ri=         $des_res[6];	# key for reliability of refinement model (zscore)
$des_rip=        "Rip" ;	# key for reliability of refinement model (zscore)
$des_riD=        $des_res[11];	# key for reliability of refinement model (best-snd)



$des_top_prd=    "Tprd";
$des_top_obs=    "Tobs";
$des_top_rid=    "Trid";
$des_top_rip=    "Trip";
$des_TPok=       "TPok";
$des_TPokt=      "TPokt";
$des_TPokts=     "TPokts";

if ($opt_phd eq "unk"){		# security
    $opt_phd="htm";}


				# ------------------------------
				# directories: add '/'
foreach $kwd (keys %par) {
    next if ($kwd !~/^dir/);
    next if (length($par{$kwd})==0 || $par{$kwd} eq "unk" );
    $par{$kwd}.="/"          if ($par{$kwd} !~ /\/$/);}


				# ------------------------------
				# (0) digest file (list?)
				# ------------------------------
$#fileTmp=0;
foreach $fileIn (@fileIn){
    if ( ($#fileIn==1 && $LisList) || $fileIn =~/\.list/) {
	($Lok,$msg,$file,$tmp)=
	    &fileListRd($fileIn);if (! $Lok){ print "*** ERROR $scrName: input list\n",$msg,"\n";
					      exit; }
	@tmpf=split(/,/,$file); 
	push(@fileTmp,@tmpf);
	next;}
    push(@fileTmp,$fileIn);
}
@fileIn= @fileTmp;
$#fileTmp=0;			# slim-is-in

				# ------------------------------
				# read swissprot names (and store)
if (-e $file_names) {
    open($fhin, $file_names)
	|| die "*** $scrName failed to open file=$file_names\n";
	
    while (<$fhin>){
	$_=~s/\n//g;
	($id,$de)=split(/\t/,$_);
	$id=~s/\s//g;
	$names{$id}=$de;
    }
    close($fhin);
}

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
    open($fhoutProt, ">".$fileOut_protprd) 
	|| warn "-*- WARN $scrName: failed open new=$fileOut_protprd\n";

    printf $fhoutProt "%-s\t%-5s\t%-5s\t%-3s\t%-4s\t%-4s\t%-4s\t%-4s\n",
    "id","nres","nali","top","nhtm","2nd","riSeg","riTop";
	
				# read line 'NALIGN =' grepped from HSSP file
				# HACK 28-10-96
    if ( defined $fileNali && -e $fileNali ) {
	open($fhin,$fileNali)
	    || warn("-*- $scrName: failed to open file=$fileNali\n");

	while(<$fhin>){if (length($_)<3){next;}
		       $_=~s/\n//g;
		       ($txt,$num)=split(/\s+/,$_);$num=~s/\s//g;
		       $txt=~s/^.*\///g;	# purge path
		       $txt=~s/\.hssp.*NALIGN//g;
		       $nali{"$txt"}=$num;}close($fhin);}
}


foreach $fileIn (@fileIn) {
    @tmp=
    %rd=&rd_rdb_associative($fileIn,@rdb_arguments,
			    "body",@des_rd);
				# missing data
    foreach $des (@des_rd){
	next if ($des!~/RI/i || defined $rd{$des,1});
	foreach $itres (1..$rd{"NROWS"}){
	    $rd{$des,$itres}=0;
	}
    }
    
    if ($rd{"NROWS"}<$nresMin) {	# skip short ones
	++$nexclNresMin;
	next; }
    ++$ctfile;
    $id=$fileIn;$id=~s/^.*\/([^\.]*)\..*/$1/;
    push(@id,$id);
				# defaults for missing Topology
    $rd{"HTMTOP_OBS"}=  "unk"     if (! defined $rd{"HTMTOP_OBS"});
    $rd{"HTMTOP_PRD_A"}="unk"     if (! defined $rd{"HTMTOP_PRD_A"});
    $rd{"HTMTOP_PRD_S"}="unk"     if (! defined $rd{"HTMTOP_PRD_S"});

    if ($opt=~/ref/){		# process header
	foreach $kwd ("REL_BEST","REL_BEST_DIFF","REL_BEST_DPROJ"){
	    $rd{$kwd}=0 if (! defined $rd{$kwd});
	}
	$rd{"NHTM_2ND_BEST"}=$rd{"NHTM_BEST"} if (! defined $rd{"NHTM_2ND_BEST"});
	    
	$rel_best= $rd{"REL_BEST"};$rel_best=~s/^.*\s+([\d\.]+)\s+.*$/$1/;$rel_best=~s/\s//g;
	$rel_bestD=$rd{"REL_BEST_DIFF"};$rel_bestD=~s/^.*\s+([\d\.]+)\s+.*$/$1/;
	$rel_bestp=$rd{"REL_BEST_DPROJ"};$rel_bestp=~s/^.*\s+([\d\.]+)\s+.*$/$1/;
	$rel_bestD=~s/\s//g;$rel_bestp=~s/\s//g;
	if (defined $rd{"NHTM_2ND_BEST"}){
	    $nprd2=  $rd{"NHTM_2ND_BEST"};$nprd2=~s/^.*\s+([\d\.]+)\s+.*$/$1/;$nprd2=~s/\s|\n//g;}
	else {
	    $nprd2=$rd{"NHTM_BEST"};}

	push(@ri,   $rel_best);
	push(@riD,  $rel_bestD);
	push(@rip,  $rel_bestp);
	push(@nprd2,$nprd2); }

    if (! $Lprd_only){
	if (defined $rd{"HTMTOP_OBS"}){
	    $top_obs=$rd{"HTMTOP_OBS"};
	    $top_obs=~s/^.*\s+(\w+)\s+\(.*$/$1/g;
	}
	else {
	    $top_obs="unk";}
	push(@top_obs,$top_obs);
    }
				# for topology model
    if ($opt eq "top"){
	$ref_nhtm=    $rd{"NHTM_BEST"};     $ref_nhtm=~s/^.*\s+(\d+)\s+\(.*$/$1/g;
	$top_prd_all= $rd{"HTMTOP_PRD_A"};  $top_prd_all=~s/^.*\s+(\w+)\s+\(.*$/$1/g;
	$top_prd_sep= $rd{"HTMTOP_PRD_S"};  $top_prd_sep=~s/^.*\s+(\w+)\s+\(.*$/$1/g;
	$top_nhtm_all=$rd{"HTMTOP_NHTM_A"}; $top_nhtm_all=~s/^.*\s+(\d+)\s+\(.*$/$1/g;
	$top_nhtm_sep=$rd{"HTMTOP_NHTM_S"}; $top_nhtm_sep=~s/^.*\s+(\d+)\s+\(.*$/$1/g;
	$top_rid_all= $rd{"HTMTOP_RID_A"};  $top_rid_all=~s/^.*\s+([\d\-.]+)\s+\(.*$/$1/g;
	$top_rid_sep= $rd{"HTMTOP_RID_S"};  $top_rid_sep=~s/^.*\s+([\d\-.]+)\s+\(.*$/$1/g;
	$top_rip_all= $rd{"HTMTOP_RIP_A"};  $top_rip_all=~s/^.*\s+([\d\-.]+)\s+\(.*$/$1/g;
	$top_rip_sep= $rd{"HTMTOP_RIP_S"};  $top_rip_sep=~s/^.*\s+([\d\-.]+)\s+\(.*$/$1/g;
	push(@top_prd_all,$top_prd_all);    push(@top_prd_sep,$top_prd_sep);
	push(@top_nhtm_all,$top_nhtm_all);  push(@top_nhtm_sep,$top_nhtm_sep);
	push(@top_rid_all,$top_rid_all);    push(@top_rid_sep,$top_rid_sep);
	push(@top_rip_all,$top_rip_all);    push(@top_rip_sep,$top_rip_sep);

    }
    else {
	$top_prd="unk"; $top_rid=$top_rip=0;
	if (defined $rd{"HTMTOP_PRD"}){
	    $top_prd=$rd{"HTMTOP_PRD"}; $top_prd=~s/^.*\s+(\w+)\s+\(.*$/$1/g;}
	if (defined $rd{"HTMTOP_RID"}){
	    $top_rid=$rd{"HTMTOP_RID"}; $top_rid=~s/^.*\s+([-\d\.]+)\s*\(.*$/$1/g;}
	if (defined $rd{"HTMTOP_RIP"}){
	    $top_rip=$rd{"HTMTOP_RIP"}; $top_rip=~s/^.*\s+([-\d\.]+)\s*\(.*$/$1/g;}
	push(@top_prd,$top_prd);push(@top_rid,$top_rid);push(@top_rip,$top_rip);
				# print file: 1 line per protein
	if ($Lprd_only){
	    $xnhtm= $rd{"NHTM_BEST"};     $xnhtm=~s/^.*\s+(\d+)\s+\(.*$/$1/g;
	    $xn2=   $rd{"NHTM_2ND_BEST"}; $xn2=~s/^.*\s+([\d\.]+)\s+.*$/$1/;$xn2=~s/\s|\n//g;
	    $xriseg=$rd{"REL_BEST_DPROJ"};$xriseg=~s/^.*\s+([\d\.]+)\s+.*$/$1/;
	    $xtop=  $rd{"HTMTOP_PRD"};    $xtop=~s/^.*\s+(\w+)\s+\(.*$/$1/g;
	    $xritop=$rd{"HTMTOP_RIP"};    $xritop=~s/^.*\s+([\d\-.]+)\s+\(.*$/$1/g;
	    $idLoc=$id; $idLoc=~s/_.*$//g;
	    if (defined $rd{"HSSP_NALIGN"}){
		$nali=$rd{"HSSP_NALIGN"};}
	    elsif(defined $nali{$idLoc}){
		$rd{"HSSP_NALIGN"}=$nali{$idLoc};
		$nali=$nali{$idLoc};}
	    else {print "*** missing nali for idLoc=$idLoc, id=$id,\n";
		  $nali=0;}
				# hack to avoid errors in top
	    if (($xtop ne 'in')&&($xtop ne 'out')){$xtop='xxx';}
				# write
	    printf $fhoutProt "%-s\t%5d\t%5d\t%-3s\t%4d\t%4d\t%4d\t%4d\n",
	    $id,$rd{"NROWS"},$nali,$xtop,$xnhtm,$xn2,$xriseg,$xritop;
	}
    }

    $all{$id,"NROWS"}=$rd{"NROWS"};
    if (defined $rd{"HSSP_NALIGN"}){$all{$id,"HSSP_NALIGN"}=$rd{"HSSP_NALIGN"};}
    if (defined $rd{"HSSP_THRESH"}){$all{$id,"HSSP_THRESH"}=$rd{"HSSP_THRESH"};}
    foreach $des (@des_rd){
	$all{$id,$des}="";
	foreach $itres (1..$rd{"NROWS"}){
	    next if (!defined $rd{$des,$itres});
	    $all{$id,$des}.=$rd{$des,$itres}; }
				# convert L->" "
	if ($des=~/O.*L|P.*L/){
            if ($opt_phd eq "htm") {
                $all{$id,$des}=~s/E/ /g;}
	    $all{$id,$des}=~s/L/ /g;} }
    if ($opt eq "top"){
	$all{$id,$des_top_rid,"all"}=$top_rid_all;
	$all{$id,$des_top_rid,"sep"}=$top_rid_sep;
	$all{$id,$des_top_rip,"all"}=$top_rip_all;
	$all{$id,$des_top_rip,"sep"}=$top_rip_sep;
	$all{$id,"ref","nhtm"}=$ref_nhtm;
	$all{$id,"nhtm","all"}=$top_nhtm_all;$all{$id,"nhtm","sep"}=$top_nhtm_sep;
	$all{$id,"top","all"}= $top_prd_all;$all{$id,"top","sep"}=$top_prd_sep; }
    else {
	$all{$id,$des_top_rid}=$top_rid;
	$all{$id,$des_top_rip}=$top_rip;
    }
    foreach $kwd ($des_top_rid,$des_top_rip){
#	$all{$id,$kwd}=~s/\s//g;
    }
}
#undef %nali;			# hack 28-10-96 (set 0 to save space)


				# --------------------------------------------------
				# analyse segment accuracy
				# --------------------------------------------------
$idvec= ""; foreach $id (@id) {$idvec.="$id\t";} $idvec=~s/\t$//g;

if (!$Lprd_only){
    %res=
	&anal_seg($idvec,$symh,$des_obs,$des_prd,
		  $des_Nok,$des_Pok,$des_Poks,$des_Nobs,$des_Nprd,%all);}
else {
    %res=
	&anal_seg_prd($idvec,$symh,$des_aa,$des_prd,$des_Nprd,%all);
    &wrt_res_statprd($fileOut_statprd,$fhout3,"STDOUT");
    print "--- $scrName output in: \t $fileOut_det2,$fileOut_det,$fileOut_statprd,\n"
	if ($Lscreen);
    exit;}
				# add ri
if ($opt=~/ref/){
    foreach $it(1..$#id){$res{$id[$it],$des_rip}=  $rip[$it];}
    foreach $it(1..$#id){$res{$id[$it],$des_riD}=  $riD[$it];}
    foreach $it(1..$#id){
	if (defined $nprd2[$it]){
	    $res{$id[$it],$des_Nprd2}=$nprd2[$it];}
	else {
	    $res{$id[$it],$des_Nprd2}=$nprd[$it];}
    }
}
				# missing data
if (! defined $res{$id[1],$des_Nprd2}){
    foreach $it(1..$#id){
	$res{$id[$it],$des_Nprd2}=$res{$id[$it],$des_Nprd};
    }}
&anal_top();
				# --------------------------------------------------
				# now write out
				# --------------------------------------------------
$desvec=""; foreach $des (@des_res){$desvec.="$des\t";} $desvec=~s/\t$//g;
$idvec= ""; foreach $id (@id) {$idvec.="$id\t";} $idvec=~s/\t$//g;

&compile_accmat;
&compile_random; 
&wrt_res("STDOUT",",",$opt,$idvec,$desvec,%res);

open($fh, ">".$fileOut) 
    || warn "*** $scrName: failed to write to fileout=$fileOut\n";
&wrt_res($fh,"\t",$opt,$idvec,$desvec,%res);
close($fh);

if ($par{"LlongHelix"}){
    $fileOutLong=$fileOut."_long" if (! defined $fileOutLong);
    open($fh, ">".$fileOutLong) 
	|| warn "*** $scrName: failed to write to fileout=$fileOutLong\n";
    &wrtLong($fh,"\t");
    close($fh);
}

print "--- fileout    =$fileOut\n" if ($Lscreen && -e $fileOut);
print "--- fileoutLong=$fileOutLong\n" if ($Lscreen && $par{"LlongHelix"});
exit;

#==============================================================================
# library collected (begin) lll
#==============================================================================


#===============================================================================
sub fileListRd {
    local($fileInLoc,$fhErrSbr,$extForChain,$dirLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fileListRd                  reads a list of files
#       in:                     file_list=     file with filenames
#       in:                     $fhErrSbr=     file handle to report missing files 
#                                              (0 to surpress warnings!)
#       in:                     $extForChain=  'ext1,ext2' : extensions to check for chains,
#                                              i.e. if not existing purge ext_[A-Z0-9]
#       in:                     $dirLoc=       'dir1,dir2' : directories to scan for file
#       out:                    1|0,msg
#       out:                    $list=         'file1,file2,...'
#       out:                    $chain=        'c1,c2,...' : if chains found
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fileListRd";$fhinLoc="FHIN_"."fileListRd";
				# check arguments
    return(0,"*** $sbrName: not def fileInLoc!",0)         if (! defined $fileInLoc);
    $fhErrSbr="STDOUT"                                     if (! defined $fhErrSbr);
    $extForChain=0                                         if (! defined $extForChain);
    return(0,"*** $sbrName: miss in file '$fileInLoc'!",0) if (! -e $fileInLoc);
    @extLoc=split(/,/,$extForChain)                        if ($extForChain);
    @dirLoc=split(/,/,$dirLoc)                             if ($dirLoc);
				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) ||
	return(0,"*** ERROR $sbrName: fileIn=$fileInLoc, not opened\n",0);

    $tmpChain=$tmpFile="";	# ------------------------------
    while (<$fhinLoc>) {	# read list
	$_=~s/\n|\s//g; $file=$_;
	next if (length($_)==0);
	if    (-e $file) {
	    $tmpFile.="$file,";$tmpChain.="*,";} # file ok 
	else {$Lok=0;$chainTmp="unk";
	      foreach $ext (@extLoc){ # check chain
		  foreach $dir ("",@dirLoc){ # check dir (first: local!)
		      $fileTmp=$file; $dir.="/"  if (length($dir)>0 && $dir !~/\/$/);
		      $fileTmp=~s/^(.*$ext)\_([A-Z0-9])$/$1/;
		      $chainTmp=$2               if (defined $2);
		      $fileTmp=$dir.$fileTmp; 
		      $Lok=1  if (-e $fileTmp);
		      last if $Lok;}
		  last if $Lok;}
	      if ($Lok){$tmpFile.="$fileTmp,";
			$tmpChain.="*,"          if (! defined $chainTmp || $chainTmp eq "unk");
			$tmpChain.="$chainTmp,"  if (defined $chainTmp && $chainTmp ne "unk"); }
	      else { print $fhErrSbr "-*- WARN $sbrName missing file=$_,\n";}}
    }close($fhinLoc);
    $tmpFile=~s/^,*|,*$//g;$tmpChain=~s/^,*|,*$//g;
    return(1,"ok $sbrName",$tmpFile,$tmpChain);
}				# end of fileListRd

#==============================================================================
sub func_absolute {
    local ($num)=@_;local ($tmp);
#----------------------------------------------------------------------
#   func_absolute               compiles the absolute value
#       in:                     $num
#       out:                    returned |$num|
#----------------------------------------------------------------------
    if ($num>=0){
	return($num);}
    else {
	$tmp=(-1)*$num;
	return($tmp);}
}				# end of func_absolute

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
	    if   ( ($aa[$it] ne $des) && ($aa[$it-1] eq $des) ){
		push(@end,($it-2)); }
	    elsif( ($aa[$it] eq $des) && ($aa[$it-1] ne $des) ){
		push(@beg,($it-1)); }  }
	if ($#end != $#beg) {	# consistency check!
	    print "*** get_secstr_segment_caps: des=$des, Nend=",$#end,", Nbeg=",$#beg,",\n";
	    exit;}
	foreach $it (1..$#end){	# store segment begins (Ncap) and ends (Ccap)
	    $segment{$des,"beg","$it"}=$beg[$it];
	    $segment{$des,"end","$it"}=$end[$it]; } 
	$segment{$des,"NROWS"}=$#beg;
    }
    return(%segment);
}				# end of get_secstr_segment_caps

#==============================================================================
sub is_rdbf {
    local ($fileIn) = @_ ;
    local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_rdbf                     checks whether or not file is in RDB format
#       in:                     file
#       out:                    returns 1 if is RDB, 0 else
#--------------------------------------------------------------------------------
    if (! -e $fileIn) {
	return (0);}
    $fh="FHIN_CHECK_RDB";&open_file("$fh", "$fileIn");
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
    local ($fileIn,@des_in) = @_ ;
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
    &open_file("$fhin","$fileIn");
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
		print"---            \t '$des_in', but not in file '$fileIn'\n";}
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
		print"---            \t '$des_in', but not in file '$fileIn'\n";}}}
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
	    print "*** WARNING in RDB file '$fileIn' for rows with ".
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
# library collected (end)   lll
#==============================================================================


1;
#==========================================================================================
sub anal_seg {
    local ($idvec,$symh,$des_obs,$des_prd,
	   $des_Nok,$des_Pok,$des_Poks,$des_Nobs,$des_Nprd,%all) = @_ ;
    local ($fh,@des,@id,$tmp,@tmp,$id,$it,$fhout);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    anal_seg                writes into file readable by EVALSEC
#--------------------------------------------------------------------------------
    $Lprt_det_old=1;
    $Lprt_det_new=1          if (defined %names);

				# default settings (global overwrites)
    $par{"Lseg9"}= 0            if (! defined $par{"Lseg9"});
    $par{"LsegC11"}=0           if (! defined $par{"LsegC11"});
    $par{"Lseg3"}= 1            if (! defined $par{"Lseg3"});
    $par{"noverlap3"}=3         if (! defined $par{"noverlap3"});
    $par{"noverlap9"}=9         if (! defined $par{"noverlap9"});

				# vector to array
    @id=split(/\t/,$idvec);
    $ctprot_ok=$ctprot_oksucc=$ctres_ok=$ctres_obs=$ctres_prd=0;
    $ctprot_ok9=$ctprot_okC11=0;
    $fhout="FHOUT_SEG";

    open($fhout, ">".$fileOut_det) || 
	warn "*** failed opening new($fhout)=$fileOut_det!\n";

    open($fhout2, ">".$fileOut_det2) ||
	warn "*** failed opening new($fhout2)=$fileOut_det2!\n"
	    if ($Lprt_det_new);
	
    @fhx=($fhout2);
    push(@fhx,"STDOUT")                 if ($Lscreen);
    
    printf $fhout 
	"\t   %3s\t   %3s\n","obs","prd" if ($Lprt_det_old);

    foreach $it (1..$#id){
	$id=$id[$it];
	undef %obs; undef %prd;		# ini

#	$all{$id,$des_obs}="              HHHHHHHHHHHHHHHHHHHHH                   "; # xx
#	$all{$id,$des_prd}=" HHHHHHHHHHHHH                   HHHHHHHHHHHHHHHHH    "; # xx

				# note: $x{$symh,"beg","$it"}
	%obs= &get_secstr_segment_caps($all{$id,$des_obs},$symh);
	%prd= &get_secstr_segment_caps($all{$id,$des_prd},$symh);

	$ctres_obs+=$obs{$symh,"NROWS"};
	$ctres_prd+=$prd{$symh,"NROWS"};
	$idprt=$id;
#	$idprt=~s/_ref.*|_nof.*|_fil.*//g;
	$idprt=~s/\..*$//g;
	if (! defined $idprt){
	    print "*** missing idprt=$idprt, for id=$id[$it], it=$it\n";
	    die;}
	$names{$idprt}=$idprt           if (! defined $names{$idprt});
	foreach $fhx (@fhx){
	    printf $fhx 
		"%-15s\t%-s\n",$idprt,$names{$idprt} if ($Lprt_det_new);
	}
		
				# temporary write
	if (0){
	    $max=$obs{$symh,"NROWS"};
	    $max=$prd{$symh,"NROWS"} if ($prd{$symh,"NROWS"}>$max);
	    foreach $ct (1..$max) {
		$prd=" - ";
		$obs=" - ";
		$prd=$prd{$symh,"beg",$ct}."-".$prd{$symh,"end",$ct} if (defined $prd{$symh,"beg",$ct});
		$obs=$obs{$symh,"beg",$ct}."-".$obs{$symh,"end",$ct} if (defined $obs{$symh,"beg",$ct});
		printf "%2d o=%-15s p=%-15s\n",$ct,$obs,$prd;
	    }}

	if (1){
	    print "-" x length($id)."     ....,....1....,....2....,....3....,....4\n";
	    print "$id obs=",$all{$id,$des_obs},"\n";
	    print "$id prd=",$all{$id,$des_prd},"\n";
	}

				# --------------------------------------------------
				# yy: very very stupid, change!!!
				# get overlap between segments
	undef %tmpoverlap;
	foreach $ctobs (1..$obs{$symh,"NROWS"}) {
	    $tmpoverlap{$ctobs,"maxval"}=0;
	    foreach $ctprd (1..$prd{$symh,"NROWS"}) {
				# begin
		if ($obs{$symh,"beg",$ctobs}>$prd{$symh,"beg",$ctprd}){
		    $beg=$obs{$symh,"beg",$ctobs};}
		else {
		    $beg=$prd{$symh,"beg",$ctprd};}
				# end
		if ($obs{$symh,"end",$ctobs}<$prd{$symh,"end",$ctprd}){
		    $end=$obs{$symh,"end",$ctobs};}
		else {
		    $end=$prd{$symh,"end",$ctprd};}
		$tmpoverlap{$ctobs,$ctprd}=1+$end-$beg;
		if ($tmpoverlap{$ctobs,$ctprd} < 0){
		    $tmpoverlap{$ctobs,$ctprd}=0;
		    next;
		}
		if ($tmpoverlap{$ctobs,$ctprd} > $tmpoverlap{$ctobs,"maxval"}){
		    $tmpoverlap{$ctobs,"maxpos"}=$ctprd;
		    $tmpoverlap{$ctobs,"maxval"}=$tmpoverlap{$ctobs,$ctprd};
		}
		if (0){
		    printf 
			"yy o %5d p %5d over=%5d max=%5d\n",$ctobs,$ctprd,
			$tmpoverlap{$ctobs,$ctprd},$tmpoverlap{$ctobs,"maxval"};
		}
	    }
	}

				# ini
	foreach $it(1..$prd{$symh,"NROWS"}){
	    $Lok[$it]=1;}
	$ctok=$ctsucc=$ctprt=$#txt_match=0;
	$ctok9=$ctokC11=0;
#	$ctsucc9=$ctsuccC11=0;
	
	foreach $ctprd (1..$prd{$symh,"NROWS"}){
	    $Lflag_prd[$ctprd]=0;} 


	foreach $ctobs (1..$obs{$symh,"NROWS"}) {
	    foreach $ctprd (1..$prd{$symh,"NROWS"}) {
				# skip if already counted
		next if ($Lflag_prd[$ctprd]);

				# find the helix that overlaps most with current observed
				#     only within limits $ctprd-1  ... $ctprd+1
		$ctprdBest=$ctprd;
		
		$ctprdBest=$ctprd+1 
		    if ($ctprd+1 <=$prd{$symh,"NROWS"} &&
			$tmpoverlap{$ctobs,($ctprd+1)}>$tmpoverlap{$ctobs,$ctprd});
		$ctprdBest=$ctprd-1 
		    if ($ctprd-1 >=1 &&
			$tmpoverlap{$ctobs,($ctprd-1)}>$tmpoverlap{$ctobs,$ctprd});
		$ctprd=$ctprdBest;

		if ($Lprt_det_new) {
		    ++$ctprt;
		    $Lflag_prd[$ctprd]=1;
		    $prtobs[$ctprt]=" - ";
		    $prtprd[$ctprt]=
			$prd{$symh,"beg",$ctprd}."-".$prd{$symh,"end",$ctprd};
		}
				# skip if already counted
		next if (! $Lok[$ctprd]);
				# no overlap end pred > end observed
		last if ($obs{$symh,"end",$ctobs}<$prd{$symh,"beg",$ctprd});
				# no overlap end pred < beg observed
		next if ($prd{$symh,"end",$ctprd} < $obs{$symh,"beg",$ctobs});

				# first time saying: this IS an overlap
		($Lok,$msg,$Lok3,$Lok9,$LokC11)=
		    &assGetOverlap($obs{$symh,"beg",$ctobs},$obs{$symh,"end",$ctobs},
				   $prd{$symh,"beg",$ctprd},$prd{$symh,"end",$ctprd},
				   $tmpoverlap{$ctobs,$ctprd});
#		print "xx obs ",substr($all{$id,$des_obs},$obs{$symh,"beg",$ctobs},(1+$obs{$symh,"end",$ctobs}-$obs{$symh,"beg",$ctobs})).", beg=",$obs{$symh,"beg",$ctobs}," end=",$obs{$symh,"end",$ctobs},"\n";
#		print "xx prd ",substr($all{$id,$des_prd},$obs{$symh,"beg",$ctobs},(1+$obs{$symh,"end",$ctobs}-$obs{$symh,"beg",$ctobs})).", beg=",$prd{$symh,"beg",$ctprd}," end=",$prd{$symh,"end",$ctprd},"\n";
#		print "xx begprd=",$prd{$symh,"beg",$ctprd}," endprd=",$prd{$symh,"end",$ctprd},"\n";
#		print "xx ctobs=$ctobs, ctprd=$ctprd, Lok3=$Lok3, 9=$Lok9, 11=$LokC11\n";
		if (! $Lok){
		    print 
			"*** ERROR $scrName:anal_seg:assGetOverlap\n",
			"    ctobs=$ctobs, ctprd=$ctprd, symh=$symh, msg=\n",
			$msg,"\n";
		    exit;
		}
				# overlap at least 3 residues
		if ($par{"Lseg3"} && $Lok3){
		    $fst_prd=$ctprd if (! $ctok);
		    ++$ctok;
		    push(@txt_match,"$ctobs-$ctprd");
				# succ=number correct, wrong place
		    ++$ctsucc if ($ctobs==$ctprd || ($ctprd-$fst_prd+1)==$ctobs);}

				# overlap at least 9 residues
		if ($par{"Lseg9"} && $Lok9){
#		    $fst_prd9=$ctprd if (! $ctok9);
		    ++$ctok9;
				# succ=number correct, wrong place
#		    ++$ctsucc9 if ($ctobs==$ctprd || ($ctprd-$fst_prd9+1)==$ctobs);
		}

				# overlap of centers at least 11 residues
		if ($par{"LsegC11"} && $LokC11){
#		    $fst_prdC11=$ctprd if (! $ctokC11);
		    ++$ctokC11;
				# succ=number correct, wrong place
#		    ++$ctsuccC11 if ($ctobs==$ctprd || ($ctprd-$fst_prdC11+1)==$ctobs);
		}
		foreach $fhx (@fh) {
		    printf $fhx
			"%-15s %-3d %-3d-%-3d %-3d %-3d-%-3d\n"," ",
			$ctobs,$obs{$symh,"beg",$ctobs},$obs{$symh,"end",$ctobs},
			$ctprd,$prd{$symh,"beg",$ctprd},$prd{$symh,"end",$ctprd};
		}
		$Lok[$ctprd]=0;
		last;
	    }
	}

				# --------------------------------------------------
				# stat for long helices
	if ($par{"LlongHelix"}){
	    foreach $ctobs (1..$obs{$symh,"NROWS"}) {
		$lenobs=1+$obs{$symh,"end",$ctobs}-$obs{$symh,"beg",$ctobs};
		next if (length($all{$id,$des_obs}) != length($all{$id,$des_prd}));
		$obs=substr($all{$id,$des_obs},$obs{$symh,"beg",$ctobs},$lenobs);
		$prd=substr($all{$id,$des_prd},$obs{$symh,"beg",$ctobs},$lenobs);
		($Lok,$msg,$Loktm)=
		    &assGetLongHelix($tmpoverlap{$ctobs,"maxval"},$prd);
		if (! $Lok){
		    print 
			"*** ERROR $scrName:anal_seg:assGetLongHelix\n",
			"    ctobs=$ctobs, symh=$symh, \nobs=$obs, \nprd=$prd, \nmsg=\n",
			$msg,"\n";
		    exit; }
				# store stat
		if (! defined $res{"statlong",$lenobs}){
		    $res{"statlong",$lenobs,"no"}=0;
		    $res{"statlong",$lenobs,"ok"}=0;
		    $res{"statlong",$lenobs}=1;}
		else {
		    ++$res{"statlong",$lenobs};}
		if (! $Loktm){
		    ++$res{"statlong",$lenobs,"no"};}
		else {
		    ++$res{"statlong",$lenobs,"ok"};}
#		print "xx len=$lenobs, n=",$res{"statlong",$lenobs},"\n";
	    }
	}			# end of stat for long helices

		
				# topology
	if (defined $top_prd[$it]){
	    $top_prd=$top_prd[$it];}
	else{
	    $top_prd=$top_prd_sep[$it];}
				# print details
	if ( $Lprt_det_old ){
	    ($Lok,$msg)=&assAnalsegPrtold();
	}

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
		    if (defined $prtprd[$ctprt]){
			printf $fhx "%-11s ",$prtprd[$ctprt];}
		    else { printf $fhx "%-11s "," ";}}
		print $fhx "\n"; 
	    }
	}

	$res{$id,$des_Nok}=    $ctok;
	$res{$id,$des_Nok9}=   $ctok9    if ($par{"Lseg9"});
	$res{$id,$des_NokC11}= $ctokC11  if ($par{"LsegC11"});
	$res{$id,$des_Nobs}=   $obs{$symh,"NROWS"};
	$res{$id,$des_Nprd}=   $prd{$symh,"NROWS"};
	$res{$id,$des_Pok}=    0;
	$res{$id,$des_Poks}=   0;
	$res{$id,$des_NPok9}=  0;
	$res{$id,$des_NPokC11}=0;
	$ctres_ok+=   $ctok;
	$ctres_ok9+=  $ctok9   if ($par{"Lseg9"});
	$ctres_okC11+=$ctokC11 if ($par{"LsegC11"});
				# fully correct
	if ($obs{$symh,"NROWS"}==$prd{$symh,"NROWS"}){
	    if ($par{"Lseg3"} && $obs{$symh,"NROWS"}==$ctok){
		$res{$id,$des_Pok}=100;
		++$ctprot_ok; }
	    if ($par{"Lseg9"} && $obs{$symh,"NROWS"}==$ctok9){
		$res{$id,$des_NPok9}=100;
		++$ctprot_ok9; }
	    if ($par{"LsegC11"} && $obs{$symh,"NROWS"}==$ctokC11){
		$res{$id,$des_NPokC11}=100;
		++$ctprot_okC11; }
	}
				# correct number wrong succession
	if ($par{"Lseg3"}   && $obs{$symh,"NROWS"}==$ctsucc){
	    $res{$id,$des_Poks}=100;
	    ++$ctprot_oksucc;}
#	if ($par{"Lseg9"}   && $obs{$symh,"NROWS"}==$ctsucc9){
#	    $res{$id,$des_NPoks9}=100;
#	    ++$ctprot_oksucc9;}
#	if ($par{"LsegC11"} && $obs{$symh,"NROWS"}==$ctsuccC11){
#	    $res{$id,$des_NPoksC11}=100;
#	    ++$ctprot_oksuccC11;}
#	print "xx id=$id, ctok3=$ctok, 9=$ctok9, 11=$ctokC11,\n";die;
	    
    }				# end of loop over all proteins
				# --------------------------------------------------

    close($fhout);		# file for details
    $res{"NROWS"}=   $#id;
    if ($par{"Lseg3"}){
	$res{$des_Pok}=     $ctprot_ok;
	$res{$des_Poks}=    $ctprot_oksucc;
	$res{$des_Nobs}=    $ctres_obs;
	$res{$des_Nprd}=    $ctres_prd;
	$res{$des_Nok}=     $ctres_ok;
    }
    if ($par{"Lseg9"}){
	$res{$des_NPok9}=   $ctprot_ok9;
#	$res{$des_NPoks9}=  $ctprot_oksucc9;
	$res{$des_Nok9}=    $ctres_ok9;
    }
    if ($par{"LsegC11"}){
	$res{$des_NPokC11}= $ctprot_okC11;
#	$res{$des_NPoksC11}=$ctprot_oksuccC11;
	$res{$des_NokC11}=  $ctres_okC11;
    }

    return(%res);
}				# end of anal_seg

#===============================================================================
sub assGetOverlap {
    local($obsbegLoc,$obsendLoc,$prdbegLoc,$prdendLoc,$overlapLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assGetOverlap               do the predicted and observed segments overlap
#                               or not? 
#                               returns various answers, overlap at least
#                               - 3 residues
#                               - 9 residues
#                               - centers of predicted and observed differ less than 11
#       in GLOBAL:              $par{"LsegC11"}:1=compile center11 overlap (ikeda)
#       in GLOBAL:              $par{"Lseg9"}:  1=compile 9 residue overlap (moeller)
#                               default: only 3 residue overlap
#       in:                     $obsbeg|end     first and last residue in given observed HTM
#       in:                     $prdbeg|end     first and last residue in given predicted HTM
#       in:                     $overlapLoc  overlap between predicted and observed HTM
#                               
#       out:                    1|0,msg,$Lok3(1|0),$Lok9(1|0),$LokC11  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."assGetOverlap";
				# check arguments
    return(&errSbr("not def obsbegLoc!"))          if (! defined $obsbegLoc);
    return(&errSbr("not def obsendLoc!"))          if (! defined $obsendLoc);
    return(&errSbr("not def prdbegLoc!"))          if (! defined $prdbegLoc);
    return(&errSbr("not def prdendLoc!"))          if (! defined $prdendLoc);
    return(&errSbr("not def overlapLoc!"))         if (! defined $overlapLoc);

#    print "xx overlap obsbeg=$obsbeg, end=$obsend, prdbeg=$prdbeg end=$prdend\n";

				# default settings (global overwrites)
    $par{"Lseg9"}=    0         if (! defined $par{"Lseg9"});
    $par{"LsegC11"}=  0         if (! defined $par{"LsegC11"});
    $par{"Lseg3"}=    1         if (! defined $par{"Lseg3"});
    $par{"noverlap3"}=3         if (! defined $par{"noverlap3"});
    $par{"noverlap9"}=9         if (! defined $par{"noverlap9"});

				# overlap at least 3?
    $Lok3=$Lok9=$LokC11=0;
    if    ($par{"Lseg9"} && ($overlapLoc >=$par{"noverlap9"})){
#	   (($prdbegLoc >= $obsbegLoc && $prdbegLoc <= ($obsendLoc-$par{"noverlap9"}+1)) ||
#	    ($prdendLoc <= $obsendLoc && $prdendLoc >= ($obsbegLoc+$par{"noverlap9"}-1)) ) ){

	$Lok3=1;
	$Lok9=1;
    }
    elsif ($par{"Lseg3"} && ($overlapLoc >=$par{"noverlap3"})){
#	   (($prdbegLoc >= $obsbegLoc && $prdbegLoc <= ($obsendLoc-$par{"noverlap3"}+1))||
#	    ($prdendLoc <= $obsendLoc && $prdendLoc >= ($obsbegLoc+$par{"noverlap3"}-1)))){
	
	$Lok3=1;
    }
				# compile center overlap
    if ($par{"LsegC11"}){
	$center_obs=$obsbegLoc+int(0.5*(1+$obsendLoc-$obsbegLoc));
	$center_prd=$prdbegLoc+int(0.5*(1+$prdendLoc-$prdbegLoc));
	$LokC11=1
	    if (( $center_prd >= $center_obs && ($center_prd-$center_obs)<=11 ) ||
		( $center_prd <= $center_obs && ($center_obs-$center_prd)<=11 ));
    }
    return(1,"ok $sbrName",$Lok3,$Lok9,$LokC11);
}				# end of assGetOverlap

#===============================================================================
sub assGetLongHelix {
#    local($lenThreshold,$obsbeg,$obsend,$prdbeg,$prdend) = @_ ;
    local($overMaxLoc,$prdsegLoc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assGetLongHelix             compare prediction of short vs long loops
#                               default: only 3 residue overlap
#       in:                     $obsseg         observed segment (should be $syml)
#       in:                     $obsbeg|end     first and last residue in given observed HTM
#       in:                     $prdbeg|end     first and last residue in given predicted HTM
#       out:                    1|0,msg,$Lok3(1|0),$Lok9(1|0),$LokC11  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."assGetLongHelix";
				# check arguments
    return(&errSbr("not def overMaxLoc!"))         if (! defined $overMaxLoc);
    return(&errSbr("not def prdsegLoc!"))          if (! defined $prdsegLoc);

				# NOT since 
				#     not overlapping at least $par{"NlongHelixMinOverlap"} residues
    if ($overMaxLoc < $par{"NlongHelixMinOverlap"}){
	return(1,"ok",0);
    }

				# NOT since
				#     it has a break
    return(1,"ok",0)
	if ($prdsegLoc =~/$symh$syml+$symh/);

				# OK
    return(1,"ok",1);

}				# end of assGetLongHelix

#===============================================================================
sub assAnalsegPrtold {
#    local($obsbeg,$obsend,$prdbeg,$prdend) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   assAnalsegPrtold                   who knows??
#       out:                    1|0,msg,$Lok3(1|0),$Lok9(1|0),$LokC11  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------

    $nobs=$obs{$symh,"NROWS"};
    $nprd=$prd{$symh,"NROWS"};
    $ctprd=$ctobs=1;
    printf $fhout 
	"%-s\; %-s\n",$idprt,$names{$idprt};
    $top_obs=$top_obs[$it];$top_obs=~tr/[a-z]/[A-Z]/;
    if (! defined $top_obs[$it]){
	print "xx missing topology for it=$it id=$idprt\n";
	next;
    }
    $tmp=$top_prd;$tmp=~tr/[a-z]/[A-Z]/;
    printf $fhout "\t   %3s\t   %3s\n",$top_obs,$tmp;
    while( ($ctobs<=$nobs) || ($ctprd<=$nprd) ) {
	if ($#txt_match>0){$tmp=shift(@txt_match);
			   ($obs,$prd)=split(/-/,$tmp);}
	else {$obs=($nobs+1);$prd=($nprd+1);}
	while ($ctobs < $obs){
	    printf $fhout "\t%3d-%3d\t%3s %3s\n",
	    $obs{$symh,"beg",$ctobs},$obs{$symh,"end",$ctobs}," "," ";++$ctobs;}
	while ($ctprd < $prd) {
	    printf $fhout "\t%3s %3s\t%3d-%3d\n"," "," ",
	    $prd{$symh,"beg","$ctprd"},$prd{$symh,"end","$ctprd"};++$ctprd;}
	if( ($ctobs<=$nobs) && ($ctprd<=$nprd) ) {
	    printf $fhout "\t%3d-%3d\t%3d-%3d\n",
	    $obs{$symh,"beg",$obs},$obs{$symh,"end",$obs},
	    $prd{$symh,"beg",$prd},$prd{$symh,"end",$prd};}
	++$ctobs;++$ctprd;
    }

    return(1,"ok assAnalsegPrtold");
}				# end of assAnalsegPrtold

#==========================================================================================
sub anal_seg_prd {
    local ($idvec,$symh,$des_aa,$des_prd,$des_Nprd,%all) = @_ ;
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
    $ctres_prd=0;
    $fhout="FHOUT_SEG";

    if ($Lprt_det_old){&open_file($fhout, ">$fileOut_det");}
    if ($Lprt_det_new){&open_file($fhout2, ">$fileOut_det2");}
    if ($Lscreen){push(@fhx,"STDOUT",$fhout2);}else{@fhx=($fhout2);}
				# header for old
    if ($Lprt_det_old){printf $fhout  "\t   %3s\n","prd";}
    if ($Lprt_det_new){printf $fhout2 
			   "%-10s\t%-3s\t%4s\t%4s\t%4s\t%-10s\t%-10s\t%-s\n",
			   "id","Top","Nhtm","Nali","Thssp","1st 10res","segments","name";}
    $max_nprd=0;
    foreach $it (1..$#id){
	$id=$id[$it];		# note: $x{$symh,"beg","$it"}
	%prd= &get_secstr_segment_caps($all{$id,$des_prd},$symh);
	$ctres_prd+=$prd{$symh,"NROWS"};
	$idprt=$id;$idprt=~s/_ref.*|_nof.*|_fil.*//g;
	$top_prd=$top_prd[$it];
#	$top_prd=~tr/[a-z]/[A-Z]/;
	$nprd=$prd{$symh,"NROWS"};
	$res{$id,$des_Nprd}=$prd{$symh,"NROWS"};
				# ------------------------------
				# statistics
	if (defined $res{$nprd,$top_prd}){++$res{$nprd,$top_prd};}
	else {$res{$nprd,$top_prd}=1;}
	if ($nprd>$max_nprd){$max_nprd=$nprd;}
				# ------------------------------
	if ( $Lprt_det_old ){	# print detail (old one, columns)
	    if (defined $names{$idprt}){
		printf $fhout "%-s\; %-s\n",$idprt,$names{$idprt};
		printf $fhout "\t   %3s\n",$top_prd;}
	    foreach $ctprd(1..$prd{$symh,"NROWS"}){
		printf $fhout
		    "\t%3d-%3d\n",$prd{$symh,"beg",$ctprd},$prd{$symh,"end",$ctprd};}}
				# ------------------------------
	if ($Lprt_det_new){	# print detail (new: rows)
	    $tmpaa=substr($all{$id,"$des_aa"},1,10);
	    $nalign=$thresh=0;	# number of sequences in HSSP file
	    if (defined $all{$id,"HSSP_NALIGN"}){$nalign=$all{$id,"HSSP_NALIGN"};}
	    if (defined $all{$id,"HSSP_THRESH"}){$thresh=$all{$id,"HSSP_THRESH"};}
	    $nalign=~s/\D//g;$thresh=~s/\D//g;
	    foreach $fhx (@fhx){
		printf $fhx 
		    "%-10s\t%-3s\t%4d\t%4d\t%4d\t%-10s\t",
		    $idprt,$top_prd,$prd{$symh,"NROWS"},$nalign,$thresh,$tmpaa;
		foreach $ctprd (1..$prd{$symh,"NROWS"}) {
		    $tmp=$prd{$symh,"beg",$ctprd}."-".$prd{$symh,"end",$ctprd};
		    print $fhx "$tmp,";}
		if (defined $names{$idprt}){
		    printf $fhx "\t%-s\n",$names{$idprt};}else {printf $fhx "\n";}}}
    }
    close($fhout);		# file for details
    $res{"NROWS"}=$#id;
    $res{$des_Nprd}=$ctres_prd;
				# count various
    foreach $des ("in","out"){$res{$des}=0;}
    foreach $ct (1..$max_nprd){
	foreach $des ("in","out"){
	    if (! defined $res{$ct,$des} ){$res{$ct,$des}=0;}}
	$res{$ct,"sum"}=$res{$ct,"in"}+$res{$ct,"out"};
	foreach $des ("in","out"){
	    $res{$des}+=$res{$ct,$des};}}
    return(%res);
}				# end of anal_seg_prd

#==========================================================================================
sub anal_top {
#    local ($fileIn, $chain_in, $skip) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    anal_top                   analyse topology 
#--------------------------------------------------------------------------------
    undef %accmat;		# accuracy matrix (obs,prd)
				# store topology
    foreach $it(1..$#id){$res{$id[$it],$des_top_prd}=$top_prd[$it];}
    foreach $it(1..$#id){$res{$id[$it],$des_top_obs}=$top_obs[$it];}
    foreach $it(1..$#id){$res{$id[$it],$des_top_rid}=$top_rid[$it];}
    $ok=$okt=$okts=$ct=0;		# analyse
    foreach $it(1..$#id){
	$id=$id[$it];
				# ini
	$res{$id,$des_TPok}=$res{$id,$des_TPokt}=$res{$id,$des_TPokts}=0;
	if    (defined $top_prd[$it])     {$top_prd=$top_prd[$it];}
	elsif (defined $top_prd_sep[$it]) {$top_prd=$top_prd_sep[$it];}
	else {
	    next;}

	++$ct;			# topology prd=obs
	++$accmat{$top_obs[$it],$top_prd};

	next if ( $top_obs[$it] eq "unk" || ! defined $top_obs[$it]);

	if ( $top_prd eq $top_obs[$it] ) {
	    ++$okt;$res{$id,$des_TPokt}=100;
	    if    ($res{$id,$des_Pok}>0){
		++$ok;++$okts;$res{$id,$des_TPok}=100;$res{$id,$des_TPokts}=100;}
	    elsif ($res{$id,$des_Poks}>0){
		++$okts;$res{$id,$des_TPokts}=100;
	    } 
	}
#	else {
#	    print "xx id=$id o:p prd=",$top_prd[$it],", obs=$top_obs[$it] \n";
#	}

    }
    if ($ct>0){
	$res{$des_TPok}=  $ok;
	$res{$des_TPokt}= $okt;
	$res{$des_TPokts}=$okts; 
	$res{"top_known"}=  $ct;}
    else {
	$res{$des_TPok}=$res{$des_TPokt}=$res{$des_TPokts}=999;
	$res{"top_known"}=0;
    }
}				# end of anal_top

#==========================================================================================
sub compile_accmat {
    $[ =1 ;
#--------------------------------------------------------------------------------
#    compile_accmat             computes accuracy matrix (4 x 4) for topology pred
#--------------------------------------------------------------------------------
    undef %sum; undef %q;
				# --------------------
				# sum over observed
    foreach $obs ("in","out","unk"){
	foreach $prd ("in","out","unk"){
	    if (defined $sum{$obs,"obs"}) {
		$sum{$obs,"obs"}+=$accmat{$obs,$prd};}
	    else {
		$sum{$obs,"obs"}=$accmat{$obs,$prd};}
	}
	if (defined $sum{"obs"}){ # total sum
	    $sum{"obs"}+=$sum{$obs,"obs"};}
	else {
	    $sum{"obs"}=$sum{$obs,"obs"};}
    }
				# --------------------
				# sum over predicted
    foreach $prd ("in","out","unk"){
	foreach $obs ("in","out","unk"){
	    if (defined $sum{$prd,"prd"}) { 
		$sum{$prd,"prd"}+=$accmat{$obs,$prd};}
	    else {
		$sum{$prd,"prd"}=$accmat{$obs,$prd};}
	}
	if (defined $sum{$prd,"prd"}){
	    if (defined $sum{"prd"}){
		$sum{"prd"}+=$sum{$prd,"prd"};}
	    else {$sum{"prd"}=$sum{$prd,"prd"};} 
	}
    }
				# --------------------
				# sum over correct predicted
    foreach $prd ("in","out","unk"){ # 
	if (defined $sum{"ok","prd"}){
	    $sum{"ok","prd"}+=$accmat{$prd,$prd};}
	else {
	    $sum{"ok","prd"}=$accmat{$prd,$prd};}
    }
				# --------------------
				# quotients
    foreach $des ("in","out","unk"){
	$q{$des,"obs"}=0;
	$q{$des,"prd"}=0;
				#   Q %obs
	$q{$des,"obs"}=100*($accmat{$des,$des}/$sum{$des,"obs"})
	    if (defined $accmat{$des,$des} &&
		defined $sum{$des,"obs"} && $sum{$des,"obs"}>0 );
				# Q %prd
	$q{$des,"prd"}=100*($accmat{$des,$des}/$sum{$des,"prd"})
	    if (defined $accmat{$des,$des} &&
		defined $sum{$des,"prd"} && $sum{$des,"prd"}>0);
    }				# final Q2
    $q{"q2"}=0;
    $q{"q2"}=100*($sum{"ok","prd"}/$sum{"obs"}) if ($sum{"obs"}>0);

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

    $Lcoin=0;$Lprob=0;
				# compute ratios for current data base
    foreach $des ("in","out"){
	$ran{$des,"prob"}=0;
	$ran{$des,"prob"}=$sum{$des,"obs"}/$sum{"obs"} if (defined $sum{"obs"} && 
							   defined $sum{$des,"obs"} && $sum{"obs"});
    }
    
    $ran{"in","prob"}= 0.402;
    $ran{"out","prob"}=0.598;
				# ------------------------------
				# flipping coin experiment
    if ($Lcoin) {
	foreach $des ("in","out"){ $ran{$des,"coin"}=0;} # initialise
	foreach $id (@id){
	    $tmp= rand ;
	    if ( ($tmp>=$ran{"in","prob"}) && ($res{$id,$des_top_obs} eq "out") ) {
		++$ran{"out","coin"};}
	    elsif ( ($tmp<$ran{"in","prob"}) && ($res{$id,$des_top_obs} eq "in") ) {
		++$ran{"in","coin"};}}
	$ran{"q2","coin"}=100*( ($ran{"in","coin"}+$ran{"out","coin"})/$sum{"obs"} ); 
	foreach $des ("in","out"){
	    $ran{$des,"coin"}=100*($ran{$des,"coin"}/$sum{$des,"obs"});}}
    
				# ------------------------------
				# compute random accuracy by preferences
    if ($Lprob) {
	$sum=0;
	foreach $des ("in","out"){
	    $ran{$des,"pref"}=100*($ran{$des,"prob"}*$sum{$des,"obs"}/$sum{"obs"});
	    $ran{$des,"pref"}=100*($ran{$des,"prob"});
	    $sum+=$ran{$des,"pref"}*$sum{$des,"obs"};}
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
    if ($res{"NROWS"}>0){$tmp=$res{$des_Pok}/$res{"NROWS"};}else{$tmp=0;}
    ($Lok,$msg)=
	&wrt_res_head($fh);
    
				# ------------------------------
				# names
    printf $fh "%-11s$sep","id";
    printf $fh "%4s$sep%4s$sep%4s$sep",$des_Nok,$des_Nobs,$des_Nprd;
    
    printf $fh "%4s$sep%4s$sep","NTa","NTs"              if ($opt eq "top");
    printf $fh "%3s$sep%3s$sep",$des_Pok,"Pos";
    printf $fh "%-s$sep%-s$sep",$des_Nok9,$des_NPok9     if ($par{"Lseg9"});
    printf $fh "%-s$sep%-s$sep",$des_NokC11,$des_NPokC11 if ($par{"LsegC11"});
	

    
    if ($opt=~/ref/)  {
	printf $fh "%4s$sep","Np2"; # correct to shorter name
	printf $fh "%3s$sep%5s$sep",$des_rip,$des_riD;
    }
    if ($opt eq "top"){
	printf $fh "%3s$sep%3s$sep%3s$sep","Tob","Tpa","Tps";}
    else {
	printf $fh "%3s$sep%3s$sep","Tob","Tprd";}
    printf $fh "%4s$sep%4s$sep","Qobs","Qprd";
    if ($opt eq "top"){
	printf $fh "%5s$sep%5s$sep%5s$sep%5s$sep","TRiDa","TRiPa","TRiDs","TRiPs";}
    else {
	printf $fh "%4s$sep%4s$sep","TRiD","TRip";}
    printf $fh "%4s$sep%4s$sep%4s\n","Tokt","Toks","TPok";

				# ------------------------------
				# all proteins
    $qobs=$qprd=$ri=$rip=$riD=$Nprd2=$top_rid=$top_rip=0;
    $top_rip_all=$top_rip_sep=$top_rid_all=$top_rid_sep=$nhtm_all=$nhtm_sep=0;
    foreach $it (1..$#id) {
	$res{$id,$des_Nprd}=$all{$id,"ref","nhtm"}  if ($opt eq "top");
	$id=$id[$it];
	$idprt=$id;$idprt=~s/_refpb|_refp|_ref|_fil|_nof|_top.*$//g;
	$idprt=~s/\.rdb.*$|\.dat.*$|\.tmp.*|\.txt*$//g;
	printf $fh "%-11s$sep",$idprt;
	printf $fh 
	    "%4d$sep%4d$sep%4d$sep",$res{$id,$des_Nok},
	    $res{$id,$des_Nobs},$res{$id,$des_Nprd};
	if ($opt eq "top"){
	    $nhtm_all+=$all{$id,"nhtm","all"};$nhtm_sep+=$all{$id,"nhtm","sep"};
	    printf $fh 
		"%4d$sep%4d$sep",$all{$id,"nhtm","all"},$all{$id,"nhtm","sep"};
	}
				# Pok
	printf $fh 
	    "%3d$sep%3d$sep",$res{$id,$des_Pok},$res{$id,$des_Poks};
	printf $fh 
	    "%3d$sep%3d$sep",$res{$id,$des_Nok9},$res{$id,$des_NPok9} if ($par{"Lseg9"});
	printf $fh 
	    "%3d$sep%3d$sep",$res{$id,$des_NokC11},$res{$id,$des_NPokC11} if ($par{"LsegC11"});
	
	    
	if ($opt=~/ref/){
#	    $tmp_ri=   $res{$id,"$des_ri"};
	    $tmp_rip=  $res{$id,$des_rip};
	    $tmp_riD=  $res{$id,$des_riD};
	    $tmp_Nprd2=$res{$id,$des_Nprd2};
	    printf $fh 
		"%4d$sep%3d$sep%5.3f$sep",$res{$id,$des_Nprd2},
		$res{$id,$des_rip},$res{$id,$des_riD};
	    $rip+=$tmp_rip;$riD+=$tmp_riD;$Nprd2+=$tmp_Nprd2;
	}
	if ($opt eq "top"){
	    printf $fh 
		"%3s$sep%3s$sep%3s$sep",$res{$id,$des_top_obs},
		$all{$id,"top","all"},$all{$id,"top","sep"};}
	else {
	    printf $fh "%3s$sep%3s$sep",$res{$id,$des_top_obs},$res{$id,$des_top_prd};}
	if ($res{$id,$des[2]}>0) {
	    $tmp_qobs=100*($res{$id,$des[1]}/$res{$id,$des[2]});}
	else {$tmp_qobs=0;}
	if ($res{$id,$des[3]}>0) {
	    $tmp_qprd=100*($res{$id,$des[1]}/$res{$id,$des[3]});}
	else {$tmp_qprd=0;}
	$qobs+=$tmp_qobs;$qprd+=$tmp_qprd;	# sum
	printf $fh "%4d$sep%4d$sep",int($tmp_qobs),int($tmp_qprd);
	if (defined $all{$id,$des_top_rid}){
	    $all{$id,$des_top_rid}=~s/[\s\(].*$//g;
	    $all{$id,$des_top_rid}=~s/^[^\d\.\-]*\s*//g;
	}
	if (defined $all{$id,$des_top_rip}){
	    $all{$id,$des_top_rip}=~s/[\s\(].*$//g;
	    $all{$id,$des_top_rip}=~s/^[^\d\.\-]*\s*//g;
	}

	if ($opt eq "top"){
	    $top_rid_all+=&func_absolute($all{$id,$des_top_rid,"all"});
	    $top_rip_all+=$all{$id,$des_top_rip,"all"};
	    $top_rid_sep+=&func_absolute($all{$id,$des_top_rid,"sep"});
	    $top_rip_sep+=$all{$id,$des_top_rip,"sep"};
	    printf $fh 
		"%4d$sep%4d$sep%4d$sep%4d$sep",
		$all{$id,$des_top_rid,"all"},$all{$id,$des_top_rip,"all"},
		$all{$id,$des_top_rid,"all"},$all{$id,$des_top_rip,"all"};}
	else {
	    $top_rid+=sqrt($all{$id,$des_top_rid}*$all{$id,$des_top_rid});
	    $top_rip+=$all{$id,$des_top_rip};
	    printf $fh "%4d$sep%4d$sep",$all{$id,$des_top_rid},$all{$id,$des_top_rip};}
	printf $fh 
	    "%4d$sep%4d$sep%4d\n",$res{$id,$des_TPokt},$res{$id,$des_TPokts},
	    $res{$id,$des_TPok};
    }
				# averages over all proteins
    printf $fh "%-11s$sep","all $#id";
    printf $fh "%4d$sep%4d$sep%4d$sep",$res{$des_Nok},$res{$des_Nobs},$res{$des_Nprd};
    if ($opt eq "top"){
	printf $fh "%4d$sep%4d$sep",$nhtm_all,$nhtm_sep;
    }
				# Pok
    printf $fh 
	"%3d$sep%3d$sep",
	int(100*($res{$des_Pok}/$#id)),int(100*($res{$des_Poks}/$#id));
    printf $fh 
	"%3d$sep%3d$sep",$res{$des_Nok9},int(100*($res{$des_NPok9}/$#id)) if ($par{"Lseg9"});
    printf $fh 
	"%3d$sep%3d$sep",$res{$des_NokC11},int(100*($res{$des_NPokC11}/$#id)) if ($par{"LsegC11"});

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
	"%4d$sep%4d$sep%4d\n",int(100*($res{$des_TPokt}/$tmp_known)),
	int(100*($res{$des_TPokts}/$tmp_known)),int(100*($res{$des_TPok}/$tmp_known));
}				# end of wrt_res

#===============================================================================
sub wrt_res_head {
    local($fhloc) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   wrt_res_head                write header for result file
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="wrt_res_head";

    if ($sep eq "\t") {
	print  $fhloc "# Perl-RDB\n";
    }
    print  $fhloc "# final averages:\n";
    printf $fhloc 
	"# Nok    :%6s,%4d   (N seg correct)\n",   " ",$res{$des[1]},
	"# Nobs  :%6s,%4d   (N seg observed)\n",  " ",$res{$des[2]},
	"# Nprd  :%6s,%4d   (N seg predicted)\n", " ",$res{$des[3]},
	"# Nprot :%6s,%4d   (N proteins)\n",      " ",$res{"NROWS"};
    $nprot=$res{"NROWS"};
    if ($par{"Lseg3"}){		# overlap 3
	printf $fhloc 
	    "# NPok   :%6.1f,%4d   (P correct)\n",100*($res{$des_Pok}/$nprot),$res{$des_Pok};}
				# overlap 9
    if ($par{"Lseg9"}){
	printf $fhloc 
	    "# Nok9   :%6s,%4d   (N seg correct)  \n", 
	    " ",        $res{$des_Nok9};
	printf $fhloc 
	    "# NPok9  :%6.1f,%4d   (P correct)\n",
	    100*($res{$des_NPok9}/$nprot),$res{$des_NPok9};
    }
				# overlap center 11
    if ($par{"LsegC11"}){
	printf $fhloc 
	    "# NokC11 :%6s,%4d   (N seg correct)  \n", " ",        $res{$des_NokC11};
	printf $fhloc 
	    "# NPokC11:%6.1f,%4d   (P correct)\n",100*($res{$des_NPokC11}/$nprot),$res{$des_NPokC11};}

    printf $fhloc "#    \n";
    printf $fhloc "# Tknown :%6s,%4d   (N proteins with known topology)\n"," ",$top_known;
    printf $fhloc "# TPok   :%6.1f,%4d   (P topology and Nseg correct)\n",
                         100*($res{$des_TPok}/$tmp_known),$res{$des_TPok};
    printf $fhloc "# TPokts :%6.1f,%4d   (P topology and succession correct)\n",
                         100*($res{$des_TPokts}/$tmp_known),$res{$des_TPokts};
    printf $fhloc "# TPokt  :%6.1f,%4d   (P topology correct Nseg not)\n",
                         100*($res{$des_TPokt}/$tmp_known),$res{$des_TPokt};
    printf $fhloc "#        :%6.1f,%4s   (top corr as percentage of proteins with corr seg)\n",
                         100*($res{$des_TPok}/$res{$des_Pok})," " if ($res{$des_Pok}>0);
    printf $fhloc "#        :%6.1f,%4s   (top corr as percentage of proteins with corr seg)\n",
                         0," " if ($res{$des_Pok}<=0);
    printf $fhloc "#    \n";
				# print final accuracy matrix
    &wrt_res_accmat($fhloc);

    if ($fhloc ne "STDOUT"){

	print $fhloc "#    \n";

	if ($par{"Lseg3"}){
	    print $fhloc 
		"# NOTATION: NPok       number of proteins with Nhtm pred=obs=ok (overlap 3)\n",
		"# NOTATION: NPok(id)=  100 or 0 (overlap 3)\n",
		"# NOTATION: NPoks      at least 'core' same number, i.e., succession ok\n";
	}
	if ($par{"Lseg9"}){
	    print $fhloc 
		"# NOTATION: NPok9      number of proteins with Nhtm pred=obs=ok (overlap 9)\n",
		"# NOTATION: NPok9(id)= 100 or 0 (overlap 9)\n";
	}
	if ($par{"LsegC11"}){
	    print $fhloc 
		"# NOTATION: NPokC11    number of proteins with Nhtm pred=obs=ok (centers <=11)\n",
		"# NOTATION: NPokC11_id=100 or 0 (overlap centers <=11)\n";
	}

	print $fhloc 
	    "# NOTATION: Pok        number of proteins with Nhtm pred=obs=ok\n",
	    "# NOTATION: Pok(id)    100 or 0, \n",
	    "# NOTATION: Poks       at least 'core' same number, i.e., succession ok\n",
	    "# NOTATION: Poks(id)   100 or 0, \n",
	    "# NOTATION: Ri         reliability of refinement model (zscore)\n",
	    "# NOTATION: RiD        reliability of refinement model (best-snd/len)\n",
	    "# NOTATION: Rip           as previous projected onto scale 0-9\n",
	    "# NOTATION: TRiD       difference content K+R (even-odd)\n",
	    "# NOTATION: TRip       int( min{9,sqrt(TRiD**2)} )\n",
	    "#  \n";
    }
    return(1,"ok $sbrName");
}				# end of wrt_res_head

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
	$tmp_in=$tmp_out=$tmp_sum=0;
	$tmp_in= $accmat{$obs,"in"}  if (defined $accmat{$obs,"in"});
	$tmp_out=$accmat{$obs,"out"} if (defined $accmat{$obs,"out"});
	$tmp_sum=$sum{$obs,"obs"}    if (defined $sum{$obs,"obs"});

	printf $fh 
	    "$txt%-8s |%8d %8d | %8d  | ",
	    "obs $tmp",$tmp_in,$tmp_out,$tmp_sum;
				# random
	printf $fh "%6.1f ",$ran{$obs,"coin"} if ($Lcoin);
	printf $fh "%6.1f ",$ran{$obs,"pref"} if ($Lpref);
	print $fh " | "                       if ($Lcoin||$Lpref);
				# percentages
	printf $fh "%6.1f %6.1f  |\n",$q{$obs,"obs"},$q{$obs,"prd"}; 
    }
    &wrt_res_accmat_line($fh,$txt,$Lcoin,$Lpref);
				# sum prd
    $tmp_in=$tmp_out=$tmp_sum=0;
    $tmp_in= $sum{"in","prd"}  if (defined $sum{"in","prd"});
    $tmp_out=$sum{"out","prd"} if (defined $sum{"out","prd"});
    $tmp_sum=$sum{"obs"}       if (defined $sum{"obs"});

    printf $fh 
	"$txt%-8s |%8d %8d | %8d  | ","prd SUM",
	$tmp_in,$tmp_out,$tmp_sum;

    printf $fh "%6.1f ",$ran{"q2","coin"}  if ($Lcoin);
    printf $fh "%6.1f ",$ran{"q2","pref"}  if ($Lpref);
    print  $fh " | "                       if ($Lcoin||$Lpref);

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
    while (defined $res{$ct,"sum"}){++$ct;}
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
	    $res_sum{$ct,"sum"}=$res_sum{$ct,"in"}=$res_sum{$ct,"out"}=0;
	    $res_sum{$ct,"cum"}=$res_sum{$ct,"in","cum"}=$res_sum{$ct,"out","cum"}=0;}
	$ct_caps_in=$ct_caps_out=0;
	foreach $ct(1..$max){	# print all
	    if (($ct/2)==int($ct/2)) {$Leven=1;}else{$Leven=0;}
	    if (! $Leven){$res{$ct,"caps_in"}=$res{$ct,"in"};
			  $res{$ct,"caps_out"}=$res{$ct,"out"};}
	    else{$res{$ct,"caps_in"}=$res{$ct,"caps_out"}=0;}
	    $ct_caps_in+=$res{$ct,"caps_in"};$ct_caps_out+=$res{$ct,"caps_out"};

	    printf $fh 
		"%3d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d",
		$ct,$res{$ct,"sum"},$res{$ct,"in"},$res{$ct,"out"},
		$res{$ct,"caps_in"},$res{$ct,"caps_out"},
		$res{$ct,"cum"},$res{$ct,"in","cum"},$res{$ct,"out","cum"};
	    if (($fh ne "STDOUT")&&(defined $nORF)&&($nORF>1)){
		printf $fh 
		    "\t%5d\t%5d\t%5d\n",(100*$res{$ct,"cum"}/($nORF-$nexclNresMin)),
		    (100*$res{$ct,"in","cum"}/($nORF-$nexclNresMin)),
		    (100*$res{$ct,"out","cum"}/($nORF-$nexclNresMin));}
	    else {print $fh "\n";}
				# compute sums
	    $res_sum{$ct,"sum"}+=$res{$ct,"sum"};$res_sum{$ct,"cum"}+=$res{$ct,"cum"};
	    $res_sum{$ct,"in"}+=$res{$ct,"in"};$res_sum{$ct,"out"}+=$res{$ct,"out"};
	    $res_sum{$ct,"in","cum"}+=$res{$ct,"in","cum"};
	    $res_sum{$ct,"out","cum"}+=$res{$ct,"out","cum"}; }
	printf $fh 
	    "%3s\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d",
	    "all",$res_sum{$ct,"sum"},$res_sum{$ct,"in"},$res_sum{$ct,"out"},
	    $ct_caps_in,$ct_caps_out,
	    $res_sum{$ct,"cum"},$res_sum{$ct,"in","cum"},$res_sum{$ct,"out","cum"};
	if (($fh ne "STDOUT")&&(defined $nORF)&&($nORF>1)){
	    printf $fh 
		"\t%5d\t%5d\t%5d\n",
		(100*$res_sum{$ct,"cum"}/($nORF-$nexclNresMin)),
		(100*$res_sum{$ct,"in","cum"}/($nORF-$nexclNresMin)),
		(100*$res_sum{$ct,"out","cum"}/($nORF-$nexclNresMin));}
	else {print $fh "\n";}
	    
	if ($fh ne "STDOUT"){ close($fh);}
    }
}				# end of wrt_res_statprd


#==========================================================================================
sub wrtLong {
    local ($fh,$sep)=@_;
    local ($tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    wrt_res                writes stat for long helices
#--------------------------------------------------------------------------------
				# get cumulative values (all smaller than N)
    foreach $itlen (1..$par{"NlongHelixMaxLen"}){
#	$res{"statlong",$itlen,"cum_lt","ok"}=0;
#	$res{"statlong",$itlen,"cum_lt","no"}=0;
#	$res{"statlong",$itlen,"cum_ge","ok"}=0;
#	$res{"statlong",$itlen,"cum_ge","no"}=0;
    }

    foreach $itlen (1..$par{"NlongHelixMaxLen"}){
	next if (! defined $res{"statlong",$itlen});
				# ini
	foreach $kwd1 ("cum_lt","cum_ge"){
	    $res{"statlong",$itlen,$kwd1}=0;
	    foreach $kwd2 ("ok","no"){
		$res{"statlong",$itlen,$kwd1,$kwd2}=0;
	    }}
				# all shorter than this
	foreach $itlen2 (1..($itlen-1)){
	    next if (! defined $res{"statlong",$itlen2});
#	    print "xx itlen=$itlen itlen2 lt =$itlen2\n";
	    if (defined $res{"statlong",$itlen2,"ok"}){
		$res{"statlong",$itlen,"cum_lt","ok"}+=$res{"statlong",$itlen2,"ok"};
		$res{"statlong",$itlen,"cum_lt"}+=$res{"statlong",$itlen2,"ok"};
	    }
	    if (defined $res{"statlong",$itlen2,"no"}){
		$res{"statlong",$itlen,"cum_lt","no"}+=$res{"statlong",$itlen2,"no"};
		$res{"statlong",$itlen,"cum_lt"}+=$res{"statlong",$itlen2,"no"};
	    }
	}
				# all as long or longer
	foreach $itlen2 ($itlen..$par{"NlongHelixMaxLen"}){
	    next if (! defined $res{"statlong",$itlen2});
#	    print "xx itlen=$itlen itlen2 ge =$itlen2\n";
	    if (defined $res{"statlong",$itlen2,"ok"}){
		$res{"statlong",$itlen,"cum_ge","ok"}+=$res{"statlong",$itlen2,"ok"} ;
		$res{"statlong",$itlen,"cum_ge"}+=$res{"statlong",$itlen2,"ok"} ;
	    }
	    if (defined $res{"statlong",$itlen2,"no"}){
		$res{"statlong",$itlen,"cum_ge","no"}+=$res{"statlong",$itlen2,"no"};
		$res{"statlong",$itlen,"cum_ge"}+=$res{"statlong",$itlen2,"no"};
	    }
	}
#	print "xx wrt len=$itlen, nlt=",$res{"statlong",$itlen,"cum_lt"}," nge=",$res{"statlong",$itlen,"cum_ge"},"";
#	foreach $kwd1("lt","ge"){print $kwd1;foreach $kwd2("ok","no"){print"($kwd2)=",$res{"statlong",$itlen,"cum_".$kwd1,$kwd2},", ";}print "  ";}print "\n";
    }

				# --------------------------------------------------
				# write out
				# header
    print $fh
	"# Perl-RDB accuracy in predicting long helices correctly (= no non-htm in helix + overlap >=".$par{"NlongHelixMinOverlap"}." residues)\n",
	"# NOTATION  Nok       number of helices with Nres ok\n",
	"# NOTATION  Nno       number of helices with Nres not\n",
	"# NOTATION  q         percentag of helices with NRES residues correct (Nok/Nok+Nno)\n",
	"# NOTATION  NcumLTok  cumulative number of correct for all helices of length 'lt' than current\n",
	"# NOTATION  NcumLTno  cumulative number of wrong   for all helices of length 'lt' than current\n",
	"# NOTATION  NcumGEok  cumulative number of correct for all helices of length 'ge' than current\n",
	"# NOTATION  NcumGEok  cumulative number of wrong   for all helices of length 'ge' than current\n",
	"# NOTATION  q(LT)     accuracy for all of 'lt'\n",
	"# NOTATION  q(GE)     accuracy for all of 'ge'\n",
	"# NOTATION  LT-GE     q(LT)-q(GE)\n",
	"# NOTATION  LT/GE     q(LT)/q(GE)\n",
	"# \n";
				# column names
    print $fh
	"Number of residues in helix",$sep,
	"Nok",$sep,"Nno",$sep,"q",$sep,
	"NcumLTok",$sep,
	"NcumLTno",$sep,
	"NcumGEok",$sep,
	"NcumGEno",$sep,
	"q(LT)",$sep,
	"q(GE)",$sep,
	"LT-GE",$sep,
	"LT/GE","\n";

				# data (length histogram)

    foreach $itlen (1..$par{"NlongHelixMaxLen"}){
#	next if (! defined $res{"statlong",$itlen,"cum_lt"} || ! $res{"statlong",$itlen,"cum_lt"});
#	next if (! defined $res{"statlong",$itlen,"cum_ge"} || ! $res{"statlong",$itlen,"cum_ge"});

	next if (! defined $res{"statlong",$itlen,"cum_lt"});
	next if (! defined $res{"statlong",$itlen,"cum_ge"});
	
	$tmpqnocum=0;
	$tmpqlt=0;
	$tmpqge=0;
	$tmpq=0;
	$tmpqnocum=100*($res{"statlong",$itlen,"ok"}/$res{"statlong",$itlen})
	    if ($res{"statlong",$itlen}>0);
	$tmpqlt=100*($res{"statlong",$itlen,"cum_lt","ok"}/$res{"statlong",$itlen,"cum_lt"})
	    if ($res{"statlong",$itlen,"cum_lt"}>0);
	$tmpqge=100*($res{"statlong",$itlen,"cum_ge","ok"}/$res{"statlong",$itlen,"cum_ge"})
	    if ($res{"statlong",$itlen,"cum_ge"}>0);
	$tmpq=$tmpqlt/$tmpqge
	    if ($tmpqge>0);

	printf $fh
	    "%5d$sep%5d$sep%5d$sep%7.2f$sep".
		"%5d$sep%5d$sep%5d$sep%5d$sep%7.2f$sep%7.2f$sep%7.2f$sep%7.3f\n",
		$itlen,
		$res{"statlong",$itlen,"ok"},
		$res{"statlong",$itlen,"no"},
		$tmpqnocum,
		$res{"statlong",$itlen,"cum_lt","ok"},
		$res{"statlong",$itlen,"cum_lt","no"},
		$res{"statlong",$itlen,"cum_ge","ok"},
		$res{"statlong",$itlen,"cum_ge","no"},
		$tmpqlt,$tmpqge,
		($tmpqlt-$tmpqge),
		$tmpq;
    }

    
}				# end of wrtLong
