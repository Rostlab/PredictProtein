#!/usr/sbin/perl -w
##!/usr/bin/perl -w
#
#
$[ =1 ;
$Lembl=1;

&compSecRatioIni;

				# --------------------------------------------------
				# read DSSP files 
if (0){ #x.y

&rdDsspSecStr($fileOutTmp,@fileDssp);	# note: GLOBAL out: @sec,@id

} #x.y

			# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.y
			# intermediate 'read the files generated already'
    $#id=$#sec=0;&open_file("$fhin", "$fileIn");$tmp="";
    while(<$fhin>){
	if (/^\#|^id|^10\t/){next;}$_=~s/\n//g;($id,$tmp)=split(/\t/,$_);$id=~s/\s//g;
	$tmp=~s/\s//g;$tmp=~s/[ lSTI]/L/g;$tmp=~s/[Gh]/H/g;$tmp=~s/B/E/g;$tmp=~s/([LH])E([LH])/$1\L$2/g;push(@id,$id);push(@sec,$tmp);}close($fhin);
print "x.x after read ","-" x 60, "\n";
			# xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.y
				# --------------------------------------------------
$ctOk=0;			# loop over all proteins
$#secOk=0;
foreach $it (1..$#sec){
    $sec=$sec[$it];
				# ------------------------------
				# compile segments
    ($secSeg,$num{"Nseg"},$num{"Hseg"},$num{"Eseg"},$num{"Lseg"})=
	 &getSecStrContSeg($sec);
				# exclude proteins with too few or too many segments
    if ((($num{"Hseg"}+$num{"Eseg"})<$par{"minHE"})||
	(($num{"Hseg"}+$num{"Eseg"})>$par{"maxHE"})){
	print "x.x fall off, as Nh=",$num{"Hseg"},", Ne=",$num{"Eseg"},"\n";
	print "x.x seg=$secSeg,\n";
	print "x.x len=",length($sec),",\n";
	print "x.x sec=$sec,\n";
	next;}
    ++$ctOk;			# count proteins included
    push(@secOk,$sec);
    foreach $des ("Nseg","Hseg","Eseg","Lseg"){
    	$num{"$des","$ctOk"}=$num{"$des"};}
    foreach $des (@desDi,@desTri){$num{"$des","$ctOk"}=0;}	# set zero
    $num{"id","$ctOk"}=$id[$it];

				# ------------------------------
				# compile residue statistics
    ($num{"Nres","$ctOk"},$num{"Hres","$ctOk"},$num{"Eres","$ctOk"},$num{"Lres","$ctOk"})=
	 &getSecStrContRes($sec);
    print"x.x content res ($ctOk)=";
    foreach $des("Nres","Hres","Eres","Lres"){print "$des:",$num{"$des","$ctOk"},", ";}print"\n";
    foreach $des("Nseg","Hseg","Eseg","Lseg"){print "$des:",$num{"$des","$ctOk"},", ";}print"\n";
    print "x.x id     =$id[$it],\n";
#    print "x.x for sec=$sec,\n";
    print "x.x and seg=$secSeg,\n";

				# ------------------------------
				# di-segment statistics
    $secSegHE=$secSeg;$secSegHE=~s/L//g;	# reduce to HE
    $num{"NsegHE","$ctOk"}=length($secSegHE);
	print "x.x segHE  =$secSegHE,\n";
    %tmp=
	 &getSecStrContSegDi($secSegHE,@desDi);
    $#data=0;
    foreach $des (@desDi){	# transform
	$num{"$des","$ctOk"}=$tmp{"$des"};
	push(@data,$tmp{"$des"});}
				# compute sum
    ($num{"sumDi","$ctOk"},$num{"aveDi","$ctOk"},$num{"varDi","$ctOk"})=
	&get_sum(@data);
    print"x.x num Di=";foreach $des (@desDi){print"$des:",$num{"$des","$ctOk"},",";}print"\n";

				# ------------------------------
				# tri-segment statistics
    %tmp=
	 &getSecStrContSegTri($secSegHE,@desTri);

    $#data=0;
    foreach $des (@desTri){	# transform
	$num{"$des","$ctOk"}=$tmp{"$des"};
	push(@data,$tmp{"$des"});}
				# compute sum
    ($num{"sumTri","$ctOk"},$num{"aveTri","$ctOk"},$num{"varTri","$ctOk"})=
	&get_sum(@data);

    print"x.x num Tri=";foreach $des (@desTri){print"$des:",$num{"$des","$ctOk"},",";}print"\n";
}
$nProt=$ctOk;
				# --------------------------------------------------
				# compile statistics
if ((defined $par{"fileAve"}) && (-e $par{"fileAve"})){
	%rdAve=
	    &rdAveVar($par{"fileAve"});}

foreach $des (@desWrt){
	if ($des eq "id"){
		next;}
	&compileStat($des,$nProt,$par{"fileAve"});
}
				# --------------------------------------------------
				# write
foreach $fh ($fhout,"STDOUT"){
				# all numbers
    if ($fh ne "STDOUT"){$fileOut=$par{"fileOut"};&open_file("$fhout", ">$fileOut");$sepX=$sep;}
    &wrtRes($fh,$sep,$fileIn,$nProt,@desWrt);
#    if ($fh ne "STDOUT"){close($fhout);}
				# averages and zscores
#    if ($fh ne "STDOUT"){$fileOut=$par{"fileAve"};&open_file("$fhout", ">$fileOut");$sepX=$sep;}
    &wrtResZ($fh,$sep,$fileIn,$nProt,"noHeader",@desWrt);
    if ($fh ne "STDOUT"){close($fhout);}
}

				# --------------------------------------------------
				# convert to HTML
if ( -e $par{"fileOut"}) {
	$fileHtml=$par{"fileOut"};$fileHtml=~s/\.rdb/\.html/;$file=$par{"fileOut"};
	print "---      \t '\&rdb2html($file,$fileHtml,$fhout,0)'\n";
	&rdb2html($file,$fileHtml,$fhout,0,$par{"scriptName"}); }

print 	"--- compSecRatio ended fine (hopefully).  Output in:",$par{"fileOut"},", \n";
exit;

 
#==========================================================================================
sub compSecRatioIni {
    $[ =1 ;
#--------------------------------------------------------------------------------
#    compSecRatioIni                       
#--------------------------------------------------------------------------------
    push (@INC, "/home/rost/perl", "/u/rost/perl") ;
    require "ctime.pl";		# require "rs_ut.pl" ;
    require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";

    @des=("exeDsspRd","minHE","maxHE","fileOut","fileAve","","","","","");
    				# ------------------------------
    				# help
    if ($#ARGV<1){
	print"goal:   extract from list of DSSP files SecStr content and di-sec\n";
	print"usage:  'script list_of_files'\n";
	print"note1:  you can give the list in a file or by *.dssp\n";
	print"options:";&myprt_array(",",@des);
	print"note2:  fileAve contains the averages read for zscore computations\n";
	print"note2:     if no file given taken from DSSP list\n";
	exit;}
    				# ------------------------------
    				# defaults
    $fhin=  "FHIN";$fhout= "FHOUT";
    $sep="\t";
    $fileOutTmp="x".$$."_CompSecRatio.tmp";
    if ($Lembl){
        $par{"exeDsspRd"}="/home/rost/perl/scripts/dssp_extr.pl";}
    else{
        $par{"exeDsspRd"}="/u/rost/perl/scripts/dssp_extr.pl";}
    
    if (! -e $par{"exeDsspRd"}){print "*** missing script exeDsspRd=",$par{"exeDsspRd"},",\n";
    			    exit;}
    $par{"minHE"}=      4;
    $par{"maxHE"}=      25;
    $par{"scriptName"}= "compSecRatio.pl (orphans)";
    
    @desSingle=  ("H","E","L");
    @desDi=      ("HH","HE","EH","EE");
    @desTri=     ("HHH","HEH","HHE","HEE","EEH","EHH","EHE","EEE");
    
    @desWrt= ("id","Nres","Nseg","NsegHE");
    foreach $des (@desSingle){$tmp="$des"."res";push(@desWrt,$tmp);}
    foreach $des (@desSingle){$tmp="$des"."seg";push(@desWrt,$tmp);}
    foreach $des (@desDi)    {$tmp="$des";push(@desWrt,$tmp);}
    foreach $des (@desTri)   {$tmp="$des";push(@desWrt,$tmp);}
    
    foreach $des(@desWrt){ if ($des eq "id"){next;}else {$form{"$des"}="4d";}}
    foreach $des("id"){$form{"$des"}="-8s";}

    				# ------------------------------
    				# get command line arguments
    $fileIn=$ARGV[1];
    $fileOut=$fileIn."_out";if ($fileOut=~/^\/data/){$fileOut=~s/^.\///g;}
    if (! defined $par{"fileOut"}){
	$par{"fileOut"}="OutNum-".$fileIn;$par{"fileOut"}=~s/^.*\///g;
	$par{"fileOut"}=~s/\..*$/\.rdb/g;}
    
    if (0){	# x.y
    @fileDssp=			# get file names
        &get_in_database_files("DSSP",@ARGV);
    				# get key-word options
    foreach $_(@ARGV){$arg=$_;if (-e $arg){next;}
    		  foreach $des (@des){
    		      if ($arg=~/^$des=/){$arg=~s/^$des=|\s//g;$par{"$des"}=$arg;
    					  last;}}}
	} # x.y
}				# end of compSecRatioIni

#==========================================================================================
sub compileStat {
    local ($desLoc,$nProtLoc,$fileAve) = @_ ;
    local (@data,$it,$zit,$Lok,$desTmp,$LaveRd);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    compileStat                compiles averages and z-scores over proteins read
#       in (GLOBAL):   		$num{"$des","$it"}
#       out (GLOBAL):		$res{"$des","x"} 
#				with 
#				x = aveN, varN (numbers), aveP, varP (percentages)
#				  = zN1..zNn , zP1..zPn (1..n = number of proteins)
#                               and $num{"$des","$xit"}, with $xit = P$it
#--------------------------------------------------------------------------------
    if ((! defined $fileAve)||(! -e $fileAve)){
	$LaveRd=0;}else{$LaveRd=1;}
				# --------------------------------------------------
    $#data=0;			# averages on counts
    foreach $it (1..$nProtLoc){
	if (! defined $num{"$desLoc","$it"}){
	    next;}
    	push(@data,$num{"$desLoc","$it"});}
    ($res{"$desLoc","aveN"},$res{"$desLoc","varN"})=
	&stat_avevar(@data);
    print "x.x for desLoc=$desLoc, ave=",$res{"$desLoc","aveN"},",\n";
				# ------------------------------
				# take averages read or compiled?
    if ($LaveRd){
	$ave=$rdAve{"$desLoc","aveN"};$var=$rdAve{"$desLoc","varN"};}
    else {
	$ave=$res{"$desLoc","aveN"};  $var=$res{"$desLoc","varN"};}

				# --------------------------------------------------
    foreach $it (1..$nProtLoc){ # z-scores on counts
	$zit="zN".$it;
	if (! defined $num{"$desLoc","$it"}){$res{"$desLoc","$zit"}="xx";
					     next;}
	if ($var > 0){
	    $res{"$desLoc","$zit"}=( ($num{"$desLoc","$it"}-$ave)/sqrt($var) );}
	else {
	    $res{"$desLoc","$zit"}=0;}}
				# --------------------------------------------------
    $#data=0;			# averages on percentages
    foreach $it (1..$nProtLoc){
	if (! defined $num{"$desLoc","$it"}){
	    next;}
				# ------------------------------
				# get correct sum to normalise
	$Lok=0;	foreach $desTmp("Nres","Hres","Eres","Lres"){
		    if ($desLoc eq $desTmp){$Lok=1;last;}}
	if ($Lok){$sum=$num{"Nres","$it"};}
	if (! $Lok){
		foreach $desTmp("Nseg","NsegHE","Hseg","Eseg","Lseg"){
		    if ($desLoc eq $desTmp){$Lok=1;last;}}
		if ($Lok){$sum=$num{"Nseg","$it"};}}
	if (! $Lok){
		foreach $desTmp(@desDi){
		    if ($desLoc eq $desTmp){$Lok=1;last;}}
		if ($Lok){$sum=$num{"sumDi","$it"};}}
	if (! $Lok){
		foreach $desTmp(@desTri){
		    if ($desLoc eq $desTmp){$Lok=1;last;}}
		if ($Lok){$sum=$num{"sumTri","$it"};}}
	if (! $Lok){
		print "*** ERROR compileStat: des ($desLoc) not recognised\n";}
	else {
		if ($sum>0){$perc=100*($num{"$desLoc","$it"}/$sum);}else{$perc=0;}
		$pit="P".$it;$perc=
		$num{"$desLoc","$pit"}=$perc;
		push(@data,$perc);}}
    ($res{"$desLoc","aveP"},$res{"$desLoc","varP"})=
	&stat_avevar(@data);
    print "x.x for percentages des=$desLoc, ave=",$res{"$desLoc","aveN"},",\n";
				# ------------------------------
				# take averages read or compiled?
    if ($LaveRd){
	$ave=$rdAve{"$desLoc","aveP"};$var=$rdAve{"$desLoc","varP"};}
    else {
	$ave=$res{"$desLoc","aveP"};  $var=$res{"$desLoc","varP"};}
				# ------------------------------
    foreach $it (1..$nProtLoc){ # z-scores on percentages
	$zit="zP".$it;
	if (! defined $num{"$desLoc","$it"}){$res{"$desLoc","$zit"}="xx";
					     next;}
	if ($var > 0){
	    $res{"$desLoc","$zit"}=(($num{"$desLoc","$it"}-$ave)/sqrt($var));}
	else {
	    $res{"$desLoc","$zit"}=0;}}
}				# end of compileStat

#==========================================================================================
sub getSecStrContRes {
    local ($secIn) = @_ ;
    local ($nAll,$nH,$nE,$nL,$secH,$secE,$secL);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   getSecStrContRes            compute number of residues in each Sec Str
#--------------------------------------------------------------------------------
    $nAll=$nH=$nE=$nL=0;$nAll=length($secIn);
    $secH=$secE=$secL=$secIn;
    $secH=~s/[EL]//g;$secE=~s/[HL]//g;$secL=~s/[HE]//g;
    $nH=length($secH);$nE=length($secE);$nL=length($secL);
    return($nAll,$nH,$nE,$nL);
}				# end of getSecStrContRes

#==========================================================================================
sub getSecStrContSeg {
    local ($secIn) = @_ ;
    local ($nAll,$nH,$nE,$nL,$secH,$secE,$secL);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   getSecStrSegNum             compute number of SecStr segments
#--------------------------------------------------------------------------------
    $nH=$nE=$nL=$nAll=0;
    $secIn=~s/EE+/E/g;$secIn=~s/LL+/L/g;$secIn=~s/HH+/H/g;
    $secH=$secE=$secL=$secIn;
    $secH=~s/[EL]//g;$secE=~s/[HL]//g;$secL=~s/[HE]//g;
    $nH=length($secH);$nE=length($secE);$nL=length($secL);$nAll=length($secIn);
    return($secIn,$nAll,$nH,$nE,$nL);
}				# end of getSecStrSegNum

#==========================================================================================
sub getSecStrContSegDi {
    local ($secSegLoc,@pattern) = @_ ;
    local (%numLoc,$di,$segTmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   getSecStrContSegDi          compute statistics for HH, HE, EH, EE
#--------------------------------------------------------------------------------
    %numLoc=0;
    foreach $di (@pattern){
	$segTmp=$secSegLoc;
	if ($di =~/^HH|^EE/){	# replace pattern by
		$replace=substr($di,1,1);}
	else {  $replace="x";}
	$ct=0;
	while ($segTmp =~ /$di/){
		++$ct;
		$segTmp=~s/$di/$replace/;}
	$numLoc{"$di"}=$ct;}
    return(%numLoc);
}				# end of getSecStrContSegDi

#==========================================================================================
sub getSecStrContSegTri {
    local ($secSegLoc,@pattern) = @_ ;
    local (%numLoc,$tri,$segTmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   getSecStrContSegTri          compute statistics for HHH, HEH, HHE, HEE, ..
#--------------------------------------------------------------------------------
    
    %numLoc=0;
    foreach $tri (@pattern){
	$segTmp=$secSegLoc;
	if ($tri =~/^HHH|^EEE|HEH|EHE/){	# replace pattern by
		$replace=substr($tri,2,2);}
	else {  $replace="x";}
	$ct=0;
	while ($segTmp =~ /$tri/){
		++$ct;
		$segTmp=~s/$tri/$replace/;}
	$numLoc{"$tri"}=$ct;}
    return(%numLoc);
}				# end of getSecStrContSegTri

#==========================================================================================
sub rdAveVar {
    local ($fileLoc) = @_ ;
    local (%rdAve,$fhinLoc,$Lfst,@tmp,$itName,@nameLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rdAveVar                   reads AVE and VAR from file
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_rdAveVar";
    &open_file("$fhinLoc", "$fileLoc"); $Lfst=0;
    while(<$fhinLoc>){
	$_=~s/\n//g;
	if (/^\#/)        { next;}
	if (! $Lfst)      { @nameLoc=split(/\t/,$_); $Lfst=1;}
	if (! /^ave|^var/){ next;}
	@tmp=split(/\t/,$_); foreach $tmp(@tmp){$tmp=~s/\s//g;}
	foreach $itName(1..$#nameLoc){
	    $rdAve{"$nameLoc[$itName]","$tmp[1]"}=$tmp[$itName];}}close($fhinLoc);
    return(%rdAve);    
}				# end of rdAveVar

#==========================================================================================
sub rdDsspSecStr {
    local ($fileOutTmp,@fileDsspLoc) = @_ ;
    local ($ct,$file,$exe,$arg,$fhinLoc,$tmp,$id);
    $[ =1 ;
#--------------------------------------------------------------------------------
#    rdDsspSecStr               reads the secondary structure for a given DSSP file
#       in:			@files
#       in (GLOBAL):		$par{"x"}, x=exeDsspRd
#       out (GLOBAL):		@sec,@id
#--------------------------------------------------------------------------------
    $fhinLoc="FHIN_rdDsspSecStr";
    $ct=0;
    for $file (@fileDsspLoc){
        ++$ct;
    				# extracting secondary structure
        $exe=$par{"exeDsspRd"};
        $arg="$file notScreen ss fileOut=$fileOutTmp";
        print"--- rdDsspSecStr: system \t $exe $arg\n";
        system("$exe $arg");
    				# reading sec str string
        &open_file("$fhinLoc", "$fileOutTmp");    
        $tmp="";
        while(<$fhinLoc>){$_=~s/\n//g;$tmp.="$_";}close($fhinLoc);
        $tmp=~s/[ STI]/L/g;	# replace blank by L
        $tmp=~s/G/H/g;		# G by H
        $tmp=~s/B/E/g;		# B by E
        $tmp=~s/([LH])E([LH])/$1\L$2/g;
    				# note x.y there seem to be 'h' and 'I'
        $id=$file;$id=~s/^.*\///g;$id=~s/\.dssp//g;$id[$ct]=$id;
        print "x.x 2:$tmp, ($id)\n";
        $sec[$ct]=$tmp;
    }
				# x.x intermediat output
    &open_file("$fhout", ">$fileOut");    
    print $fhout "# Perl-RDB\n";
    printf $fhout "%-10s\t%-s\n","id","sec";
    printf $fhout "%-10s\t%-s\n","10"," ";
    foreach $it (1..$#sec){printf $fhout "%-10s\t%-s\n",$id[$it],$sec[$it];}close($fhout);
    print "x.x fileOut=$fileOut, exit after having written the file\n";
    exit;			# x.x
}				# end of rdDsspSecStr

#==========================================================================================
sub wrtRes {
    local ($fhLoc,$sepLoc,$fileData,$nProtLoc,@desLoc)=@_;
    local ($des,$tmp,$sepX,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtRes                      writes results into RDB file
#          in: 			$fileData (file originally read, e.g. list name)
#				$nProt (number of proteins taken)
#   GLOBAL in:			%form{"$des"} format of column $des
#  				$par{"x"}, x=minHE and maxHE , fileAve
#				   minimal and maximal number of segments taken
# 				%num{"$des","$it"}, where
#				   $it = number of protein 
#				   $des= id, Nres, Nseg, NsegHE,
#					Hres,Eres,Lres, Hseg,Eseg,Lseg, 
#					HH,EE,HE,EH, HHH,HEH,EEE,EHE, HEE,HHE,EEH,EHH
#					or: sumDi, sumTri
#				it -> Pit gives percentages
#--------------------------------------------------------------------------------
    if ($fhLoc ne "STDOUT"){
	print  $fhLoc "# Perl-RDB\n# \n";
	printf $fhLoc "# %-10s: %-s\n","SOURCE",$fileData;
	foreach $des ("minHE","maxHE"){
		printf $fhLoc "# %-10s: %-s\n",$des,$par{"$des"};}
	if ((defined $par{"fileAve"})&&(-e $par{"fileAve"})){
	    printf $fhLoc "# %-10s: %-s\n","AVE/VAR from",$par{"fileAve"};}
    }

    foreach $des(@desLoc){	# header
	$tmp="%".$form{"$des"};$tmp=~s/d/s/;$tmp=~s/\.\d+f/s/;
	if ($des eq $desLoc[$#desLoc]){$sepX="\n";}else{$sepX=$sepLoc;}
	printf $fhLoc "$tmp$sepX",$des;}
    if ($fhLoc ne "STDOUT"){
      foreach $des(@desLoc){	# format
	$tmp="%".$form{"$des"};$tmp=~s/d/s/;$tmp=~s/\.\d+f/s/;
	$tmpX=&form_perl2rdb($form{"$des"});
	if ($des eq $desLoc[$#desLoc]){$sepX="\n";}else{$sepX=$sepLoc;}
	printf $fhLoc "$tmp$sepX",$tmpX;}}
				# ------------------------------
    foreach $it (1..$nProtLoc){	# body
	foreach $des(@desLoc) {
	    if (! defined $num{"$des","$it"}){$tmpX="xx";}else {$tmpX=$num{"$des","$it"};}
	    $tmp="%".$form{"$des"};
	    if ($des eq $desLoc[$#desLoc]){$sepX="\n";}else{$sepX=$sepLoc;}
	    printf $fhLoc "$tmp$sepX",$tmpX;}}
				# ------------------------------
    foreach $it (1..$nProtLoc){	# percentages
	foreach $des(@desLoc) {
	    if ($des eq "id"){
	    	$tmp="%".$form{"$des"};
		printf $fhLoc "$tmp$sepLoc","P".$num{"$des","$it"};
		next;}
	    if ($des =~/^Nres|^Nseg/){
	    	printf $fhLoc "%-3s $sepLoc","-";
		next;}
	    $pit="P"."$it";
	    if (! defined $num{"$des","$pit"}){$tmpX="xx";}else {$tmpX=$num{"$des","$pit"};}
	    $tmp="%".$form{"$des"};
	    if ($des eq $desLoc[$#desLoc]){$sepX="\n";}else{$sepX=$sepLoc;}
	    printf $fhLoc "$tmp$sepX",$tmpX;}}
}				# end of wrtRes

#==========================================================================================
sub wrtResZ {
    local ($fhLoc,$sepLoc,$fileData,$nProtLoc,$modeHeader,@desLoc)=@_;
    local ($des,$tmp,$sepX,$it);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   wrtResZ                     writes averages and zscores into RDB file
#          in: 			$fileData (file originally read, e.g. list name)
#				$nProt (number of proteins taken)
#   GLOBAL in:			%form{"$des"} format of column $des
#  				$par{"x"}, x=minHE and maxHE 
#				   minimal and maximal number of segments taken
# 				%res{"$des","$it"}, where
#				   $it = number of protein 
#					or: aveN, varN, aveP, varP
#					(average on numbers 'N' and percentages 'P')
#				   $des= id, Nres, Nseg, NsegHE,
#					Hres,Eres,Lres, Hseg,Eseg,Lseg, 
#					HH,EE,HE,EH, HHH,HEH,EEE,EHE, HEE,HHE,EEH,EHH
#--------------------------------------------------------------------------------
    if ($modeHeader ne "noHeader"){
        if ($fhLoc ne "STDOUT"){
		print  $fhLoc "# Perl-RDB\n# \n";
		printf $fhLoc "# %-10s: %-s\n","SOURCE",$fileData;
		foreach $des ("minHE","maxHE"){
			printf $fhLoc "# %-10s: %-s\n",$des,$par{"$des"};}}

    	foreach $des(@desLoc){	# header
		$tmp="%".$form{"$des"};$tmp=~s/d/s/;$tmp=~s/\.\d+f/s/;
		if ($des eq $desLoc[$#desLoc]){$sepX="\n";}else{$sepX=$sepLoc;}
		printf $fhLoc "$tmp$sepX",$des;}
    	if ($fhLoc ne "STDOUT"){
      	    foreach $des(@desLoc){	# format
	  	$tmp="%".$form{"$des"};$tmp=~s/d/s/;$tmp=~s/\.\d+f/s/;
		$tmpX=&form_perl2rdb($form{"$des"});
	    if ($des eq $desLoc[$#desLoc]){$sepX="\n";}else{$sepX=$sepLoc;}
	    printf $fhLoc "$tmp$sepX",$tmpX;}}
    }
				# ------------------------------
				# averages and variance
    foreach $desAve ("aveN","varN","aveP","varP"){
    	foreach $des (@desLoc){
	    if ($des eq "id"){
	    	$tmp="%".$form{"$des"};
		printf $fhLoc "$tmp$sepLoc","$desAve";
		next;}
	    if (! defined $res{"$des","$desAve"}){
		$tmpX="xx";
		print "*** not defined: desAve=$desAve, des=$des,\n";}
	    else {$tmpX=$res{"$des","$desAve"};}
	    $tmp="%".$form{"$des"};
	    if ($des eq $desLoc[$#desLoc]){$sepX="\n";}else{$sepX=$sepLoc;}
	    printf $fhLoc "$tmp$sepX",$tmpX;}}
				# ------------------------------
				# zscores
    foreach $preZ("zN","zP"){ # on numbers and percentages
        foreach $it (1..$nProtLoc){
	    foreach $des(@desLoc) {
	    	if ($des eq "id"){$tmp="%".$form{"$des"};
			      printf $fhLoc "$tmp$sepLoc",$preZ." ".$num{"$des","$it"};
		              next;}
	        $zit=$preZ.$it;
	        if (! defined $res{"$des","$zit"}){$tmpX="xx";}else {$tmpX=$res{"$des","$zit"};}
	        $tmp="%4.1f";if ($des eq $desLoc[$#desLoc]){$sepX="\n";}else{$sepX=$sepLoc;}
	        printf $fhLoc "$tmp$sepX",$tmpX;}}
     }
}				# end of wrtResZ

#==========================================================================================
sub subx {
#    local ($fileIn, $chain_in, $skip) = @_ ;
    $[ =1 ;
#--------------------------------------------------------------------------------
#    subx                       
#         c
#       in:
#         A                     
#       out:
#         A                     A
#--------------------------------------------------------------------------------

}				# end of subx

