#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal= "extract alis for seq from FSSP which have certain features \n";
$scrGoal.="     \t         (e.g. %id>x) returns also seq profile!\n";
$scrGoal.="     \t input:  fssp_id.list\n";
$scrGoal.="     \t output: stat\n";
#$scrGoal.="     \t         \n"; 
#  
# 
#----------------------------------------------------------------------
# fssp_ide_ali
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# usage: 	fssp_ide_ali.pl list of fssp files
#
# task:		extract seq from fssp which have certain features (e.g. %id>x)
# 		
#
#------------------------------------------------------------------------------#
#	Copyright				        	2002	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       650 West, 168 Street, BB217					       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Jul,    	2002	       #
#------------------------------------------------------------------------------#

#----------------------------------------------------------------------#
#	Burkhard Rost			July,	        1994           #
#			changed:		,      	1994           #
#			changed:	March	,      	1997           #
#	EMBL				Version 0.1                    #
#	Meyerhofstrasse 1                                              #
#	D-69117 Heidelberg		(rost@EMBL-Heidelberg.DE)      #
#----------------------------------------------------------------------#


$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
@kwd=sort (keys %par);

$Ldebug=       0;
$Lverb=        0;
$Lscreen=      0;
$Lscreen2=     0;

$Lexchange=    0;		# no exchange matrix

$lower_seqide= 0;
$upper_seqide= 99;
$file_constr=  "unk";
$rlali_min=     0.0;		# minimal ratio: (2*Lali)/(L1+L2)
$z_min=         0.0;		# minimal zscore
$len_min=      20;			# minimal length of hits accepted
				# read other input arguments
$LsomeOut=     0;
$LdoKing=      1;		# separate kingdoms
$LdoKing=      0;		# separate kingdoms

$fileKing=     "/home/rost/pub/data/seqUniq849-kingdom.list";
$file_metric=  "/home/rost/pub/topits/mat/Maxhom_McLachlan.metric";
#$file_metric=  "/home/rost/pub/topits/Maxhom_Blosum.metric";

$scale=        10;		# determines grid for histogram
$scale=         1;		# determines grid for histogram

$Lread_alis=   1;		# take seqide from FSSP table, or recompile (weighted)?
$Lread_alis=   0;
$dir_fssp=      "/data/fssp/"; 
$ext_fssp=      "_dali.fssp";
$Lheader=      1;
$Lpair=        0;		# write pairs of sim|not|unk
$zdali_sim3d=  4.5;		# if pair with zdali > this -> judged ARE similar
$zdali_dif3d=  1.5;		# if pair with zdali < this -> judged NOT similar
				# in between both: unk

@des=("NR","IDE","LALI","LSEQ2","Z","STRID1","STRID2","RMSD");

				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal";
    print  "use:  '$scrName '\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-15s %-s\n","","low",     "x", "cut_off lower seq_id";
    printf "%5s %-15s=%-15s %-s\n","","up",      "x", "cut_off upper seq_id";
    printf "%5s %-15s=%-15s %-s\n","","zmin",    "x", "cut_off low zscores";
    printf "%5s %-15s=%-15s %-s\n","","rlali",   "x", "cut_off 2*Lali/L1+L2";
    printf "%5s %-15s=%-15s %-s\n","","lmin",    "x", "cut_off min length";

    printf "%5s %-20s %-10s %-s\n","","[exch|matrix|metric]","no val",   "write exchange metric (default=not)";

    printf "%5s %-15s %-15s %-s\n","","doKing",  "no value","separate kingdoms, file with 'pdbid TAB swiss TAB king'";
    printf "%5s %-15s %-15s %-s\n","","ali",     "no value","evaluate alis (by default skipped)";
    printf "%5s %-15s %-15s %-s\n","","noali",   "no value","do not evaluate alis ";

    printf "%5s %-15s=%-15s %-s\n","","file",    "x", "file_constraint";
    printf "%5s %-15s %-15s %-s\n","","",        "",  "means pairs if match id (2nd seq) found in file";

    printf "%5s %-15s %-15s %-s\n","","",   "no value","";

    printf "%5s %-15s=%-15s %-s\n","","fileOut", "x",       "name of output file";
    printf "%5s %-15s=%-15s %-s\n","","dirOut",  "x",       "if given: name fileIn=fileOut BUT in dirOut";

    printf "%5s %-15s %-15s %-s\n","","pair",    "no value","write pairs similar and to exclude";
    printf "%5s %-15s=%-15s %-s\n","","zsim",    "x",       "minimal zDali to call similar (def $zdali_sim3d)";
    printf "%5s %-15s=%-15s %-s\n","","zdif",    "x",       "maximal zDali to call different (def $zdali_dif3d)";
    printf "%5s %-15s %-15s %-s\n","","",        "",        "in between previous=unk (2 exclude)";

#    printf "%5s %-15s=%-15s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-15s %-s\n","","",        "",         "continued";
#    printf "%5s %-15s %-15s %-s\n","","",   "no value","";

    printf "%5s %-15s %-15s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-15s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-15s %-s\n","","verb|-s",  "no value","verbose";
#    printf "%5s %-15s %-15s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s=%-15s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-15s %-s\n","","",   "no value","";
				# special
    if (($#ARGV==1 && $ARGV[1]=~/^special/) ||
	($#ARGV>1 && $ARGV[1] =~/^(-h|help)/ && $ARGV[2]=~/^spe/)){
    }

    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-15s %-s\n","","-" x 15 ,"-" x 15,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-15s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd});
	    next if ($kwd=~/^\s*$/);
	    if    ($par{$kwd}=~/^\d+$/){
		$tmp2.=sprintf("%5s %-15s= %10d %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    elsif ($par{$kwd}=~/^[0-9\.]+$/){
		$tmp2.=sprintf("%5s %-15s= %10.3f %9s %-s\n","",$kwd,$par{$kwd}," ","(def)");}
	    else {
		$tmp2.=sprintf("%5s %-15s= %-15s %-s\n","",$kwd,$par{$kwd},"(def)");} 
	} 
	print $tmp, $tmp2       if (length($tmp2)>1);
    }
    exit;}
				# initialise variables
$fhin="FHIN";$fhout="FHOUT";
$#fileIn=0;
$dirOut=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=        $1;}
    elsif ($arg=~/^dirOut=(.*)$/i)        { $dirOut= $1;
					    $dirOut.="/"     if ($dirOut !~ /\/$/);}


    elsif ($arg=~/^notScreen2/)           { $Lscreen2=       0;}
    elsif ($arg=~/^notScreen/)            { $Lscreen=        0;}
    elsif ($arg=~/^verbose2/)             { $Lscreen2=       1;}
    elsif ($arg=~/^verbose/)              { $Lscreen=        1;}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}

#    elsif ($arg=~/^=(.*)$/){ $=$1;}

    elsif ($arg=~/low=([\d\.]+)/)         { $lower_seqide=   $1;}
    elsif ($arg=~/up=([\d\.]+)/)          { $upper_seqide=   $1;}
    elsif ($arg=~/file=(\S+)/)            { $file_constr=    $1;}

    elsif ($arg=~/zmin=([\d\.]+)/)        { $z_min=          $1;}
    elsif ($arg=~/rlali=([\d\.]+)/)       { $rlali_min=      $1;}
    elsif ($arg=~/lmin=([\d\.]+)/)        { $len_min=        $1;}

    elsif ($arg=~/^pair$/i)               { $Lpair=          1;}
    elsif ($arg=~/^zsim=(.*)$/i)          { $zdali_sim3d=    $1;}
    elsif ($arg=~/^zdif=(.*)$/i)          { $zdali_dif3d=    $1;}


    elsif ($arg=~/doKing=/)               { $tmp=$arg;$tmp=~s/^.*=|\s//g;
					    $LdoKing=$tmp;}
    elsif ($arg=~/doKing/)                { $LdoKing=        1;}
    elsif ($arg=~/fileKing=(\S+)/)        { $fileKing=       $1;}
    elsif ($arg=~/^ali$/)                 { $Lread_alis=     1;}
    elsif ($arg=~/^noali$/)               { $Lread_alis=     0;}
    elsif ($arg=~/^(exch|matrix|metric)$/){ $Lexchange=      1;
					    $Lread_alis=     1;}
    elsif ($arg=~/^(exch|matrix|metric)$/){ $Lread_alis=     1;}

    elsif ($arg=~/^fileOut/){
	$LsomeOut=1;
	if    ($arg=~/^fileOutIdpairs=/){$arg=~s/^.*=//g;$fileOut{"idpairs"}=$arg;}
	elsif ($arg=~/^fileOutOrphans=/){$arg=~s/^.*=//g;$fileOut{"orphans"}=$arg;}
	elsif ($arg=~/^fileOut=/)       {$arg=~s/^.*=//g;$fileOut=$arg;}}

    elsif (-e $arg)                       { push(@fileIn,$arg); }

    else {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;}}}

$fileIn=$fileIn[1];
die ("*** ERROR $scrName: missing input $fileIn!\n") 
    if (! -e $fileIn);
				# 
$dirOut.="/"                    if ($dirOut && $dirOut !~ /\/$/);

($Date,$date)=&sysDate();

$file_in=$fileIn[1];
if ($Lverb){
    print "--- $scrName: \n" ;
    print "--- filein=$file_in, seqide $lower_seqide - $upper_seqide\n";
    print "--- minimal zscore=$z_min\n" if ($z_min>0);
    print "--- minimal (2*Lali/L1+L2)=$rlali_min\n" if ($rlali_min>0);
    print "--- minimal zscore=$z_min\n" if ();
    print "--- minimal zscore=$z_min\n" if ();
}

$tmp=$fileIn;$tmp=~s/.*\///g;
if (! defined $fileOut){
    if ($fileIn=~/list/){
	$tmp=~s/fssp//g;
	$fileOut="Out-"."$tmp"; $fileOut=~s/\.list//g; }
    else{
	$fileOut="Out-fssp";}
    $fileOut.="-"."$lower_seqide"."-"."$upper_seqide"; 
    $tmp=int(10*$z_min)/10;$fileOut.="-Z"."$tmp" if ($z_min>0);
    if ($rlali_min>0.1){ 
	foreach $add (0.9,0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1){
	    last if($rlali_min>$add);
	}
	$fileOut.="-R"."$add";}}

@des_fileOut=
    ("gr","grdet",
     "histide","histdist","histwide","histwnide","histocc",
     "idok","idnot",
     "idpairs","idpairs2","orphans",
     "exchangeSeq","exchangeSec","exchangeSeqSec",
     "pairsim3d","pairunk3d",
     );

if ($LsomeOut){
    $#tmp=0;
    foreach $des(@des_fileOut){
	push(@tmp,$des) if (defined $fileOut{$des});
    }
    @des_fileOut=@tmp;}
else {
    if ($fileOut !~/\.[^._-]+$/){$fileOut.=".c";}
    $fileOut=~s/\-\-/\-/g;
    $fileOut{"gr"}=            $fileOut; $fileOut{"gr"}            =~s/Out/Gr/;
    $fileOut{"grdet"}=         $fileOut; $fileOut{"grdet"}         =~s/Out/Grdet/;
    $fileOut{"histide"}=       $fileOut; $fileOut{"histide"}       =~s/Out/HisIde/;
    $fileOut{"histdist"}=      $fileOut; $fileOut{"histdist"}      =~s/Out/HisDist/;
    $fileOut{"histwide"}=      $fileOut; $fileOut{"histwide"}      =~s/Out/HisWide/;
    $fileOut{"histwnide"}=     $fileOut; $fileOut{"histwnide"}     =~s/Out/HisWnide/;
    $fileOut{"histocc"}=       $fileOut; $fileOut{"histocc"}       =~s/Out/HisOcc/;
    $fileOut{"idok"}=          $fileOut; $fileOut{"idok"}          =~s/Out/OutOk/;
    $fileOut{"idnot"}=         $fileOut; $fileOut{"idnot"}         =~s/Out/OutNot/;
    $fileOut{"exchangeSeq"}=   $fileOut; $fileOut{"exchangeSeq"}   =~s/Out/Exchseq/;
    $fileOut{"exchangeSec"}=   $fileOut; $fileOut{"exchangeSec"}   =~s/Out/Exchsec/;
    $fileOut{"exchangeSeqSec"}=$fileOut; $fileOut{"exchangeSeqSec"}=~s/Out/Exchseqsec/;
    $fileOut{"idpairs"}=       $fileOut; $fileOut{"idpairs"}       =~s/^Out/Id/;
    $fileOut{"idpairs2"}=      $fileOut; $fileOut{"idpairs2"}      =~s/^Out/Id2/;
    $fileOut{"orphans"}=       $fileOut; $fileOut{"orphans"}       =~s/^Out/Orph/;
    $fileOut{"pairsim3d"}=     $fileOut; $fileOut{"pairsim3d"}     =~s/^Out/Pairsim3d/;
    $fileOut{"pairunk3d"}=     $fileOut; $fileOut{"pairunk3d"}     =~s/^Out/Pairunk3d/;
    foreach $des ("orphans","idpairs","idpairs2"){
	$fileOut{$des}=~s/\.c$/\.list/;}}

# print "xx files=\n";foreach $des (@des_fileOut){print "xx des=$des, write '",$fileOut{$des},"'\n";}exit;

$fhout=          "FHOUT";
$fhoutgr=        "FHOUT_GR";
$fhoutgrdet=     "FHOUT_GRDET";
$fhhist=         "FHOUT_HIST";
$fhhistdist=     "FHOUT_HISTDIST";
$fhhistocc=      "FHOUT_HISTOCC";
#$fhidok=         "FHOUT_IDOK";
#$fhidnot=        "FHOUT_IDNOT";
$fhin=           "FHIN";
$fhin_constr=    "FHIN_CONSTR";
$fhout_exchange= "FHOUT_EXCHANGE";
$fhout_orphans=  "FHOUT_ORPHANS";

				# ------------------------------
				# correct some settings
				# correct min zScore
$z_min=$zdali_dif3d             if ($Lpair && $z_min < $zdali_dif3d);

#----------------------------------------
# read list
#----------------------------------------
$fileOutSave=$fileOut;
open($fhout, ">".$fileOut)    || die "*** $scrName failed to open new(fileOut)=$fileOut\n";
if (defined $fileOut{"gr"}) {
    $file=$fileOut{"gr"}; 
    open($fhoutgr, ">".$file) || warn "*** $scrName failed to open new(file)=$file\n";
}
if ($Lread_alis && (defined $fileOut{"grdet"}) ){
    $file=$fileOut{"grdet"}; 
    open($fhoutgrdet, ">".$file) || warn "$scrName failed opening new=$file!\n";
    print $fhoutgrdet "# weighting metric: $file_metric\n";
    printf 
	$fhoutgrdet 
	    "%-6s\t%-6s\t%5s\t%5s\t%6s\t%6s\t%6s\n",
	    "id1","id2","side","len","\%ide","\%wnide","wide";}
$#id_constr=0;			# read the constraints
if (-e $file_constr){ 
    open($fhin_constr, $file_constr) || 
	warn "*** $scrName failed to read (file_constr)=$file_constr\n";
    while(<$fhin_constr>){
	$_=~s/\n|\s//g;
	next if (length($_)<1);
	$_=~s/.*\/|\..*//g;
	push(@id_constr,$_);}
    close($fhin_constr);}

foreach $i ($lower_seqide..$upper_seqide){ # initialise histogram counts
    $histo{$i}=0;
    foreach $king("euka","proka","archae","eu-pro"){
	$histo{$i,"$king"}=0;
    }}

foreach $dist (-100 .. 100){
    $histdist{$dist}=0;}

$ctprot=0; $ctprotok=0; $cthits=0;

$#file_fssp=0;
foreach $fileIn (@fileIn){
    if (! &is_fssp($fileIn) ) {
	open("FILEINLIST", $fileIn)
	    || die "*** failed to read FSSP=$fileIn\n";
	while ( <FILEINLIST> ) {
	    $tmp=$_;$tmp=~s/\s|\n//g;
	    if (length($tmp)>1) {
		if (length($tmp)==4)    {$fileInfssp="$dir_fssp"."$tmp"."$ext_fssp"; }
		elsif (length($tmp)==5) {$fileInfssp="$dir_fssp"."$tmp"."$ext_fssp"; }
		elsif ($tmp=~/^\/data/) {$fileInfssp=$tmp; }
		else {print "*** ERROR: length wrong for:$tmp|\n"; 
		      exit; }
		if (-e $fileInfssp) {
		    push(@file_fssp,$fileInfssp); } }} close(FILEINLIST); }
    else {
	push(@file_fssp,$fileIn); }}

				# ------------------------------
				# read kingdom
				# ------------------------------
open($fhin, $fileKing) || 
    warn "*** $scrName failed to read (fileKing)=$fileKing\n";

$ct=0;
while(<$fhin>){
    $_=~s/\n//g;
    next if (/^\#/);		# ignore RDB header
    ++$ct;
    next if ($ct<3);		# ignore RDB names/formats
    @tmp=split(/\t/,$_);
    $tmp[1]=~s/\s//g;$tmp[3]=~s/\s//g;
    $king{"$tmp[1]"}=$tmp[3];}
close($fhin);

				# ----------------------------------------
				# initialise the metric /profile stuff
				# ----------------------------------------
print "metric=$file_metric, read=$Lread_alis,\n"
    if ($Lscreen);
if (-e $file_metric && $Lread_alis){
    $string_aa= &metric_ini;	# aa's: = "VLIMFWYGAPSTCHRKQENDBZ"
				# read metric
    %metric=    &metric_rd($file_metric);
				# find min/max
    $#key=$metric_min=$metric_max=0; 
    @key=keys %metric;
    foreach $key(@key){
	if    ($metric{$key} > $metric_max){$metric_max=$metric{$key};}
	elsif ($metric{$key} < $metric_min){$metric_min=$metric{$key};} }
    $metric_intervall=($metric_max-$metric_min)/100;
				# normalise metric (0-1)
    %metricnorm=
	&metric_norm_minmax(0,1,$string_aa,%metric);
}
				# ------------------------------
				# for exchange matrix
if ($Lread_alis){

    $string_sec="HEL";
    @string_sec=split(//,$string_sec);
    @array_sec=@sec_symbol=@string_sec;

    $string_seq=$string_aa;
    $#array_aa=0;
    @array_aa=split(//,$string_aa);
    @array_seq=@array_aa;

#    $string_seqor=join("|",@array_seq);
#    $string_secor=join("|",@array_sec);
				# ini exchange metric
    foreach $aa1(@array_aa,"sum"){
	foreach $aa2(@array_aa,"sum"){
	    $exchangeSeq{$aa1,$aa2}=0;}}

    foreach $it1 (@sec_symbol,"sum"){
	foreach $it2 (@sec_symbol,"sum"){
	    $exchangeSec{$it1,$it2}=0;}}

    foreach $it1seq (@array_seq){foreach $it1sec (@array_sec){
	$exchangeSeqSec{$it1seq.$it1sec,"sum"}=0;
	$exchangeSeqSec{"sum",$it1seq.$it1sec}=0;
	foreach $it2seq (@array_seq){foreach $it2sec (@array_sec){
	    $exchangeSeqSec{$it1seq.$it1sec,$it2seq.$it2sec}=0;
	}}}}
}
				# --------------------------------------------------
				# now for entire list
				# --------------------------------------------------
if (defined $fileOut{"orphans"}) {
    $fileOut=$fileOut{"orphans"}; # file to write orphans (no hit found)
    open($fhout_orphans, ">".$fileOut) || 
	warn "-*- $scrName failed to open fileOut(orphans)=$fileOut!\n";
}

$#idrd=$#idok=$#idnot=$#sumint_ide=$#sum_wide=$#sumint_wnide=0;
undef %flag;

undef %pairsim;
undef %pairunk;

foreach $fileInfssp(@file_fssp) {
    ++$ctprot;
    $tmpid=$fileInfssp;$tmpid=~s/.*\/|\.fssp.*//g;$id1=$tmpid;
    push(@idrd,$tmpid);$idPairs{$tmpid}="";
    printf "file:%-28s seq id > %3d for:\n",$fileInfssp, $lower_seqide 
	if ($Lscreen);
    print $fhout "file:$fileInfssp\n";
				# ----------------------------------------
				# reading one file
    $#posok=$#arprint=0;
    open("FILEINFSSP",$fileInfssp)||
	die "*** $scrName fileIn(fssp)=$fileInfssp not opened!\n";

    while ( <FILEINFSSP> ) { 
	last if (/^\#\# PROTEINS|^\#\# SUMMARY/); 
				# length of search sequence
	if (/^SEQLENGTH/){
	    $len1=$_;$len1=~s/^SEQLENGTH\s+//g;
	    $len1=~s/\s|\n//g;}}
    $#arprint=0;
    $Lnot_orphans=0;
    while ( <FILEINFSSP> ) {
	$_=~s/^\s*//g;
	if (length($_)<2 || $_=~/^\#\# ALI/) {
	    $tmpline=$_;
	    last;}
				# read header
	if ($_=~/^NR\./ && $Lheader) { 
	    $tmp1=substr($_,1,66); 
	    push(@arprint,$tmp1);
	    $#tmp=0;@tmp=split(/\s+/,$_);$it=0;
	    foreach $tmp (@tmp){
		++$it;
		foreach $des (@des) {
		    if ($tmp =~ /$des/) { 
			$pos{$des}=$it; 
			last; }}}
	    if ($cthits==0){
		if (defined $fileOut{"gr"}) {
		    foreach $des (@des){
			if ($des eq $des[$#des]){
			    print $fhoutgr "$des\n";}
			else {                  
			    print $fhoutgr "$des\t";}}} }}
				# read protein info in header
	else {
	    @tmp=split(/\s+/,$_);
	    foreach $des (@des) {
		$tmp=$pos{$des};
		$rd{$des}=$tmp[$tmp];$rd{$des}=~s/\s|://g;
	    }
	    $flag=0;
	    $flag=1		# include if right PIDE range
		if ($rd{"IDE"}>=$lower_seqide &&
		    $rd{"IDE"}<=$upper_seqide);

#	    print "x.x z=",$rd{"Z"},", l1=$len1, lali=",$rd{"LALI"},", l2=",$rd{"LSEQ2"},",\n";
	    $rlali=(2*$rd{"LALI"})/($len1+$rd{"LSEQ2"});
	    $flag=0             # exclude if zscore too low
		if ( $rd{"Z"}<$z_min );
	    $flag=0             # exclude if fraction alignment overlap too low
		if ( $rlali<$rlali_min );

				# assign: SIMILAR 3D / unclear / NOT similar 3d
	    if ($Lpair){
		$id1=$rd{"STRID1"};
		$id2=$rd{"STRID2"};
		$id1sub=substr($id1,1,4);
		$id2sub=substr($id2,1,4);
				# ignore identical proteins
		if    ($id1sub ne $id2sub && $rd{"Z"} >= $zdali_sim3d){
		    $pairsim{$id1}= "" if (! defined $pairsim{$id1});
		    $pairsim{$id1}.=$id2.","; }
		elsif ($id1sub ne $id2sub && $rd{"Z"} >= $zdali_dif3d){
		    $pairunk{$id1}= "" if (! defined $pairunk{$id1});
		    $pairunk{$id1}.=$id2.","; }
	    }
	    
				# check list of to-be-excluded
	    if ($flag && ($#id_constr>0)) {
		$flag=0;
		foreach $id_constr(@id_constr){
		    $tmpid2=substr($rd{"STRID2"},1,4);
		    last if ($flag);
		    $flag=1      if ($id_constr=~/$tmpid2/);
		}}
	    $flag=0		# exclude identical PDBids
		if ($flag && 
		    substr($tmpid,2,3) =~ substr(substr($rd{"STRID2"},1,4),2,3));
	    $flag=0		# exclude too short?
		if ($flag && ($len_min>0) &&
		    $rd{"LALI"}<$len_min);
	    next if (! $flag);

	    push(@posok,$rd{"NR"}); # add position to list
	    if (!defined $flag{$tmpid}){
		++$ctprotok;$Lnot_orphans=1;
		$histocc{$tmpid}=0; # initialise histo of Noccurrence
		push(@idok,$tmpid);
		$flag{$tmpid}=1;}
				# get HSSP distance
	    ($curve,$tmp)=
		&getDistanceNewCurveIde($rd{"LALI"});
	    $rd{"DIST"}=$dist=
		int($rd{"IDE"}-$curve);
	    ++$histdist{$dist};
#	    print "xx curve=".sprintf("%5.1f",$curve)." dist=".sprintf("%5.1f",$dist).", ide=",$rd{"IDE"},", lali=",$rd{"LALI"},"\n";
	    $tmp1=substr($_,1,66); 
	    $tmpx=$rd{"STRID2"};$tmpx=~s/-/_/g; # fssp notation 1pdb-C to 1pdb_C
	    $id2=$tmpx;
	    $idPairs{$tmpid}.=$tmpx.",";
	    push(@arprint,$tmp1);
	    if (defined $fileOut{"gr"}) {
		foreach$des(@des){
		    if($des eq $des[$#des]){
			print $fhoutgr $rd{$des},"\n";}
		    else {                  
			print $fhoutgr $rd{$des},"\t";}
		}}
	    ++$cthits;
	    $id1NoChain=substr($id1,1,4);
	    $id2NoChain=substr($id2,1,4);
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
	    ++$histocc{$tmpid}; 
	}}
				# ----------------------------------------
				# read alignments
    if ($Lread_alis) {
	$line_ali="";
	$line_ali="$tmpline"."\n" if ($tmpline =~ /\#/);
	while ( <FILEINFSSP> ) { # read all alis into @line_ali
	    last if ( /^\#\# EQUI/ );
	    $line_ali.="$_"; }
	undef %rd_ali;
				# global out %rd_ali
	&fssp_rd_ali($line_ali,@posok);

	if (0){			# yy
	    foreach $kwd (keys %rd_ali){printf "yy %-10s \t %-s\n",$kwd,$rd_ali{$kwd};}
	    die;}

				# ------------------------------
				# sequence exchange matrix
				# global OUT: %exchangeSeq
				#             also writes to fileOut'grdet'
	($Lok,$msg)=
	    &doMetricSeq();     &errScrMsg("after doMetricSeq (file=$fileInfssp)",$msg) if (! $Lok);

				# ------------------------------
				# secondary structure matrix
				# global OUT: %exchangeSec
	($Lok,$msg)=
	    &doMetricSec();     &errScrMsg("after doMetricSec (file=$fileInfssp)",$msg) if (! $Lok);

				# ------------------------------
				# sequence + sec str matrix
				# global OUT: %exchangeSeqSec
	($Lok,$msg)=
	    &doMetricSeqSec();  &errScrMsg("after doMetricSeqSec (file=$fileInfssp)",$msg) if (! $Lok);

	undef %rd_ali; 
    }
				# end of reading alignments
				# ----------------------------------------
    close(FILEINFSSP);
    print $fhout_orphans 
	"$fileInfssp\n"
	    if (! $Lnot_orphans);
	
				# end of reading one file
				# ----------------------------------------
    push(@idnot,$tmpid)
	if (!defined $flag{$tmpid}|| ! $flag{$tmpid});
	
#       ------------------------------
#       print
#       ------------------------------
    if ($#arprint >1) {
	foreach $i (@arprint) { 
	    print "$i\n"        if ($Lscreen2);
	    print $fhout "$i\n";
	} 
    }
}
close($fhout_orphans) if (defined $fileOut{"orphans"}) ;
				# ------------------------------
				# exchange matrix
                                # ------------------------------
if ($Lexchange && $Lread_alis){
    &wrt_exchangeSeq("%5d"," ","STDOUT",%exchangeSeq)
	if ($Lverb);
    if (defined $fileOut{"exchangeSeq"}) {
	$file=$fileOut{"exchangeSeq"};
	open($fhout_exchange, ">".$file) 
	     || warn "*** $scrName failed to open new(file_exchangeSeq)=$file\n";
	&wrt_exchangeSeq("%6d","\t",$fhout_exchange,%exchangeSeq);
	close($fhout_exchange); }}

if ($Lexchange && $Lread_alis){
    &wrt_exchangeSec("%5d"," ","STDOUT",%exchangeSec)
	if ($Lverb);
    if (defined $fileOut{"exchangeSec"}) {
	$file=$fileOut{"exchangeSec"};
	open($fhout_exchange, ">".$file) 
	     || warn "*** $scrName failed to open new(file_exchangeSec)=$file\n";
	&wrt_exchangeSec("%6d","\t",$fhout_exchange,%exchangeSec);
	close($fhout_exchange);
    }}

if ($Lexchange && $Lread_alis){

    &wrt_exchangeSeqSec("%5d"," ","STDOUT",%exchangeSeqSec)
	if ($Lverb);
    if (defined $fileOut{"exchangeSeqSec"}) {
	$file=$fileOut{"exchangeSeqSec"};
	open($fhout_exchange, ">".$file) 
	     || warn "*** $scrName failed to open new(file_exchangeSeqSec)=$file\n";
	&wrt_exchangeSeqSec("%6d","\t",$fhout_exchange,%exchangeSeqSec);
	close($fhout_exchange);
    }}

@fh=("$fhout");
foreach $fh (@fh){
    print $fh 
	"# statistics: \%sequence ide=($lower_seqide-$upper_seqide), ",
	"zDali>$z_min, (2*Lali/L1+L2)> $rlali_min\n";
    print $fh "# number of proteins searched:   $ctprot\n";
    print $fh "# number of proteins with hits:  $ctprotok\n";
    print $fh "# number of hits found in total: $cthits\n";}
close(FILEINLIST); close($fhout); 

close($fhoutgr)    if (defined $fileOut{"gr"});
close($fhoutgrdet) if ($Lread_alis && defined $fileOut{"grdet"});

				# --------------------------------------------------
				# write histogram for sequence identity
if (defined $fileOut{"histide"}) {
    $sum=0;
    foreach $_(@sumint_ide){
	$sum+=$_;}
    $file=$fileOut{"histide"}; 
    open($fhhist, ">".$file) || warn "$scrName failed opening new=$file!\n";
    $tmp=0;
    $tmp=($sum/($#sumint_ide*$scale))
	if (($#sumint_ide*$scale)>0);
    printf $fhhist 
	"# average over %9d proteins =%6.2f\n",$#sumint_ide,$tmp;
    if ($LdoKing){
	printf $fhhist 
	    "%4s\t%-10s\t%-10s\t%-10s\t%-10s\n","\%ide","number of pairs","euka","proka","eu-pro";
    }
    else {
	printf $fhhist "%4s\t%10s\n","\%ide","number of pairs";}

    foreach $i (($scale*$lower_seqide)..($scale*$upper_seqide)){
	if ( (defined $histo{$i}) && ($histo{$i}>0) ){
	    printf $fhhist 
		"%5.1f\t%10d",($i/$scale),$histo{$i}; 
	    if ($LdoKing){
		printf $fhhist 
		    "\t%10d\t%10d\t%10d",
		    $histo{$i,"euka"},$histo{$i,"proka"},$histo{$i,"eu-pro"};}
	    printf $fhhist "\n";
	}
    }
    close($fhhist);}
				# --------------------------------------------------
				# write histogram for HSSP distance
if (defined $fileOut{"histdist"}) {
    $file=$fileOut{"histdist"}; 
    open($fhhistdist, ">".$file) ||
	warn "*** $scrName failed to open new(file(histdist))=$file\n";
				# header
    printf $fhhistdist
	"%s\t%-s\t%-s\t%-s\t%-s\n",
	"Distance from HSSP-threshold",
	"Number of pairs",
	"NC",
	"Percentage of pairs",
	"PC";
				# find min and max
    $distmin=100;
    $distmax=-100;
    $npairs=0;
    foreach $dist (-100 .. 100){
	next if (! defined $histdist{$dist} || ! $histdist{$dist});
	$distmin=$dist if ($dist<$distmin);
	$distmax=$dist if ($dist>$distmax);
	$npairs+=$histdist{$dist};
    }
				# body
    $nctmp=0;
    foreach $dist ($distmin .. $distmax){
	$nctmp+=$histdist{$dist};
	$ptmp=  100*$histdist{$dist}/$npairs;
	$pctmp= 100*$nctmp/$npairs;
	$tmp=sprintf("%d\t%d\t%d\t%6.2f\t%6.2f\n",
		     $dist,$histdist{$dist},$nctmp,$ptmp,$pctmp);
	print $fhhistdist
	    $tmp;
	print $tmp if ($Lverb);
    }
    close($fhhistdist);
}


if ($Lread_alis ){
				# --------------------------------------------------
				# write out weighted similarity 
    if (defined $fileOut{"histwnide"}) {
	$sum=0;foreach $_(@sumint_wnide){$sum+=$_;}
	$file=$fileOut{"histwnide"}; 
	open($fhhist, ">".$file) || warn "$scrName failed opening new=$file!\n";
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
				# --------------------------------------------------
				# write out similarity 
    if (defined $fileOut{"histwide"}) {
	$sum=0;foreach $_(@sum_wide){$sum+=$_;}
	$file=$fileOut{"histwide"}; 
	open($fhhist, ">".$file) || warn "$scrName failed opening new=$file!\n";
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
    $file=$fileOut{"histocc"}; 
    open($fhhistocc, ">".$file) || warn "$scrName failed opening new=$file!\n";
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
    $file=$fileOut{"idok"};  
    open($fhout, ">".$file) || warn "$scrName failed opening new=$file!\n";
    print "--- id's of files with hits: \n" if ($Lverb);
    foreach $id (@idok){
	print $fhout "$id\n";
	print "$id, "         if ($Lverb);}
    print "\n";
    close($fhout);}
if (defined $fileOut{"idnot"}) {
    $file=$fileOut{"idnot"}; 
    open($fhout, ">".$file) || warn "$scrName failed opening new=$file!\n";
    print "--- id's of files with no hits: \n" if ($Lverb);
    foreach $id (@idnot){ 
	print $fhout "$id\n";
	print "$id, " if ($Lverb);
    }
    print"\n";close($fhout);
}
				# write identifiers
if (defined $fileOut{"idpairs"}) {
    $file=$fileOut{"idpairs"};
    open($fhout, ">".$file) || warn "$scrName failed opening new=$file!\n";
    foreach $id (@idok){ 
	print $fhout "$id\t",$idPairs{"$id"},"\n";
    }
    close($fhout);}
if (defined $fileOut{"idpairs2"}) {
    $file=$fileOut{"idpairs2"};
    open($fhout, ">".$file) || warn "$scrName failed opening new=$file!\n";
    foreach $id (@idok){
	print $fhout "$id\n"; $idPairs{"$id"}=~s/,$//g;
	@tmp=split(/,/,$idPairs{"$id"});
	foreach $id2 (@tmp){ 
	    print $fhout "$id2\n";
	}
    }
    close($fhout);}
				# pairs similar
if ($Lpair){
    $file=$fileOut{"pairsim3d"};
    open($fhout, ">".$file) || warn "$scrName failed opening new=$file!\n";
    print $fhout "# all pairs above Z-DALI ".$zdali_sim3d."\n";
    print $fhout "id1\tid2_similar_3d\n";
    foreach $id (@idrd){
	next if (! defined $pairsim{$id});
	next if ($pairsim{$id}=~/^\s*\,\s*$/);	# none found really
	$pairsim{$id}=~s/\,*$//g;
	print $fhout $id,"\t",$pairsim{$id},"\n";
    }
    close($fhout);
				# unclear stuff 2 exclude from analysis
    $file=$fileOut{"pairunk3d"};
    open($fhout, ">".$file) || warn "$scrName failed opening new=$file!\n";
    print $fhout "# all pairs to exclude Z-DALI < ".$zdali_sim3d." but >= ".$zdali_dif3d."\n";
    print $fhout "id1\tid2_unclear_3d\n";
    foreach $id (@idrd){
	next if (! defined $pairunk{$id});
	next if ($pairunk{$id}=~/^\s*\,\s*$/);	# none found really
	$pairunk{$id}=~s/\,*$//g;
	print $fhout $id,"\t",$pairunk{$id},"\n";
    }
    close($fhout);
}

print "--- find output in files:\n--- \t";
foreach $des (@des_fileOut) { 
    next if ((! defined $fileOut{$des})||(! -e $fileOut{$des}));
    print " ",$fileOut{$des},",";} 

print"$fileOutSave\n";

exit;

#===============================================================================
sub doMetricSec {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   doMetricSec                 compiles exchange metric for secondary structure
#                               
#       in/out GLOBAL:          %exchangeSec{$sec1,$sec2} number for sec str class 1/2
#                               
#       in GLOBAL:              %rd_ali    rd_ali{"sec1conv"}     sec str (HEL) of guide
#                                          rd_ali{"sec2conv",$it} sec str (HEL) of aligned
#                                            $it=@posok
#       in GLOBAL:              @posok     numbers of aligned 
#       in GLOBAL:              @array_sec array with allowed sec str states (capital)
#       in GLOBAL:              
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."doMetricSec";

    $sec1=$rd_ali{"sec1conv"};
    foreach $pos (@posok){
	$sec2=$rd_ali{"sec2conv",$pos};
	%mat= 
	    &exchangeSec($sec1,$sec2,$string_sec);
				# sum it up
	foreach $it1 (@array_sec){
	    foreach $it2 (@array_sec){
		next if (! $mat{$it1,$it2});
		$exchangeSec{$it1,$it2}+=$mat{$it1,$it2};
	    }
	}
    }

    return(1,"ok $sbrName");
}				# end of doMetricSec

#===============================================================================
sub doMetricSeq {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   doMetricSeq                 compiles the exchange metric for sequence
#                               also writes to file 'grdet'
#                               
#       in/out GLOBAL:          %exchangeSeq{$aa1,$aa2} number for amino acid pair 1/2
#                               
#       in GLOBAL:              %rd_ali    rd_ali{"seq1"} sequence of guide
#                                          rd_ali{"seq2",$it} sequence of aligned
#                                            $it=@posok
#       in GLOBAL:              @posok     numbers of aligned 
#       in GLOBAL:              @array_aa  array with allowed amino acids (capital)
#       in GLOBAL:              
#       in GLOBAL:              %metric/%metricnorm background metrices 
#                                          check out 'sub metric_rd(file_metric)'
#       in GLOBAL:              all kinds of other shit:
#       in GLOBAL:              %histo,%histo_wnide, %king, @sum_wide, @sumint_wnide,
#       in GLOBAL:              $metric_max,%fileOut('grdet'), $fhoutgrdet
#       in GLOBAL:              
#       in GLOBAL:              
#       in GLOBAL:              
#                               
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."doMetricSeq";

    $seq1=$rd_ali{"seq1"};
    foreach $pos (@posok){
	$seq2=$rd_ali{"seq2",$pos};
	($ide,$len)=   &seqide_compute ($seq1,$seq2);
	%mat= 
	    &seqide_exchange($seq1,$seq2,$string_aa);
	if (0){			# yy
	    print "yy seq1=$seq1\n";
	    print "yy seq2=$seq1\n";
	    print "yy string=$string_aa\n";
	    die;}
				# sum them
	foreach $aa1(@array_aa){
	    foreach $aa2(@array_aa){
		$exchangeSeq{$aa1,$aa2}+=$mat{$aa1,$aa2}; }}

	($wide,$len2)= 
	    &seqide_weighted($seq1,$seq2,%metric);
	($wnide,$len2)=
	    &seqide_weighted($seq1,$seq2,%metricnorm);

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
	    push(@sum_wide,$wide_perc);
	    push(@sumint_wnide,int($scale*100*$wnide_perc));
	    $tmp=int($scale*100*$wnide_perc);
	    ++$histo_wnide{$tmp};
	    $ct=$metric_min;
	    while ($ct < $metric_max){
		if ( ($wide_perc>=$ct) && ($wide_perc<=($ct+$metric_intervall)) ) {
		    ++$histo_wide{$ct};  
		    last; }
		$ct+=$metric_intervall; } 
	}
	if ( ($len>0)&& ($len2>0) ){
	    if (defined $fileOut{"grdet"}) {
		$id1=~s/[-_]//g;$id2=~s/[-_]//g;
		printf $fhoutgrdet 
		    "%-6s\t%-6s\t%5d\t%5d\t%6.1f\t%6.1f\t%6.1f\n",
		    $id1,$id2,$ide,$len,(100*$ide_perc),(100*$wnide_perc),$wide_perc; }
	}
    }
    return(1,"ok $sbrName");
}				# end of doMetricSeq

#===============================================================================
sub doMetricSeqSec {
#    local($fileInLoc,$fhErrSbr) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   doMetricSeqSec              compiles exchange metric for mix sequence / secondary structure
#                               ie 20 x 3 states
#                               
#       in/out GLOBAL:          %exchangeSeqSec{$aa1.$sec1,$aa2.$sec2} number for sec str class 1/2
#                               
#       in GLOBAL:              %rd_ali    rd_ali{"seq1"} sequence of guide
#                                          rd_ali{"seq2",$it} sequence of aligned
#                                            $it=@posok
#       in GLOBAL:              %rd_ali    rd_ali{"sec1conv"}     sec str (HEL) of guide
#                                          rd_ali{"sec2conv",$it} sec str (HEL) of aligned
#                                            $it=@posok
#       in GLOBAL:              @posok     numbers of aligned 
#       in GLOBAL:              @array_aa  array with allowed amino acids (capital)
#       in GLOBAL:              @array_sec array with allowed sec str states (capital)
#       in GLOBAL:              
#       in:                     $fileInLoc
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."doMetricSeqSec";

    $sec1=$rd_ali{"sec1conv"};
    $seq1=$rd_ali{"seq1"};

    foreach $pos (@posok){
	$sec2=$rd_ali{"sec2conv",$pos};
	$seq2=$rd_ali{"seq2",$pos};
	%mat= 
	    &exchangeSeqSec($seq1,$seq2,$string_aa,
			    $sec1,$sec2,$string_sec);
	$tmpseq1=$seq1; $tmpseq1=~s/[^AC]/ /g;
	$tmpseq2=$seq2; $tmpseq2=~s/[^AC]/ /g;
				# sum it up
	foreach $it1seq (@array_seq){
	    foreach $it1sec (@array_sec){
		foreach $it2seq (@array_seq){
		    foreach $it2sec (@array_sec){
			next if (! defined $mat{$it1seq.$it1sec,$it2seq.$it2sec} ||
				 ! $mat{$it1seq.$it1sec,$it2seq.$it2sec});
			$exchangeSeqSec{$it1seq.$it1sec,$it2seq.$it2sec}+=
			    $mat{$it1seq.$it1sec,$it2seq.$it2sec};
		    }
		}
	    }
	}
    }

    return(1,"ok $sbrName");
}				# end of doMetricSeqSec

#==============================================================================
sub exchangeSec {
    local ($s1,$s2,$array_sec) = @_ ;
    local ($ide,$len,$len2,$it,$aa1,$aa2,%mat);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   exchangeSec                exchange matrix res type X in seq 1 -> res type Y in seq 2
#       in:                     string1,string2
#       out:                    matrix
#--------------------------------------------------------------------------------
    if (! defined @array_sec || ! $#array_sec){
	$#array_sec=0;
	@array_sec=split(//,$array_sec);
    }
				# ini
    foreach $it1 (@array_sec){
	foreach $it2 (@array_sec){
	    $mat{$it1,$it2}=0;}}
				# get minimum length
    if (length($s1)>length($s2)){
	$len=length($s2);}
    else{
	$len=length($s1);}
    $ide=$len2=0;		# sum identity
    foreach $it (1..$len){
	$tmp1=substr($s1,$it,1);
	next if ($tmp1 !~/[$string_sec]/);
	$tmp2=substr($s2,$it,1);
	next if ($tmp2 !~/[$string_sec]/);
	++$len2;
	++$mat{$tmp1,$tmp2}; 
    }
    return(%mat);
}				# end of exchangeSec

#==============================================================================
sub exchangeSeqSec {
    local ($seq1,$seq2,$array_seq,$sec1,$sec2,$array_sec) = @_ ;
    local ($ide,$len,$len2,$it,$aa1,$aa2,%mat);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   exchangeSeqSec              exchange matrix res type X in seq 1 -> res type Y in seq 2
#                               also sec1 sec2
#       in:                     string1,string2
#       out:                    matrix
#--------------------------------------------------------------------------------

    if (! defined @array_sec || ! $#array_sec){
	$#array_sec=0;
	@array_sec=split(//,$array_sec);
    }
    if (! defined @array_seq || ! $#array_seq){
	$#array_seq=0;
	@array_seq=split(//,$array_seq);
    }
				# ini
    foreach $it1seq (@array_seq){
	foreach $it1sec (@array_sec){
	    foreach $it2seq (@array_seq){
		foreach $it2sec (@array_sec){
		    $mat{$it1seq.$it1sec,$it2seq.$it2sec}=0;
		}}}}

				# get minimum length
    if (length($seq1)>length($seq2)){
	$len=length($seq2);}
    else{
	$len=length($seq1);}
    $ide=$len2=0;		# sum identity

    foreach $it (1..$len){
	$tmp1seq=substr($seq1,$it,1);
	next if ($tmp1seq !~/[$string_seq]/); # any bad acid kicks out
	$tmp2seq=substr($seq2,$it,1);
	next if ($tmp2seq !~/[$string_seq]/); # any bad acid kicks out
	$tmp1sec=substr($sec1,$it,1);
	next if ($tmp1sec !~/[$string_sec]/); # any bad sec str kicks out
	$tmp2sec=substr($sec2,$it,1);
	next if ($tmp2sec !~/[$string_sec]/); # any bad sec str kicks out
	++$len2;
	++$mat{$tmp1seq.$tmp1sec,$tmp2seq.$tmp2sec}; 
    }
    return(%mat);
}				# end of exchangeSeqSec


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


#===============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#                               br 2003-08: mistake corrected
#                               
#       in:                     $lali
#       out:                    $pide
#                               
#                   OLD         pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#                   NEW         pide= 480 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);


				# saturation short: <=11
    return(100,"ok $sbrName saturation short") 
	if ($laliLoc<=11);
				# saturation long: >450
    return(19.5,"ok $sbrName saturation long") 
	if ($laliLoc>450);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
#    $loc= 510 * $laliLoc ** ($expon);
    $loc= 480 * $laliLoc ** ($expon);
    $loc=100   if ($loc > 100);	 # saturation short
    $loc=19.5  if ($loc < 19.5); # saturation long

    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde


    $date=$Date; $date=~s/(199\d|200\d)\s*.*$/$1/g;
    return($Date,$date);
}				# end of sysDate



#==============================================================================
# library collected (end)   lll
#==============================================================================


1;










