#! /usr/bin/perl -w

$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="converts position specific scoring matrix given by -Q option of PSI-Blast and predicted secondary structure and solvent accessibility into maxhom sssa-profile\n";

$help ="running instruction:\n";
$help.="$scrName MatrixFile (or list with suffix \".list\") filesec=\"name of ouput file of dsspExtrSeqSecAcc.pl\" strmat= \"structural exchange matrix\" \n";

$par{'rescale_structure'}=0;
$par{'SSMIN'}=-4; $par{'SSMAX'}=11;
$par{'StrSeqMix'}=0.4; #value between 0-1 indicating proportion of sequence influence
$par{'steepness'}     =0.05;
$par{'RI_A_weight'}   =0;
$par{'RI_S_ave_glob'} =4.8;
$par{'RI_A_ave_glob'} =2.3;


$par{"NullModel"}{"B"}=1;
$par{"NullModel"}{"O"}=1;
$par{"NullModel"}{"H"}=1;
$par{"NullModel"}{"E"}=1;
$par{"NullModel"}{"L"}=1;

#substitution probabilities from FSSP
$par{"FsspSecMat"}{"H"}{"H"}=0.329; $par{"FsspSecMat"}{"H"}{"E"}=0.011; $par{"FsspSecMat"}{"H"}{"L"}=0.128;
$par{"FsspSecMat"}{"E"}{"H"}=0.011; $par{"FsspSecMat"}{"E"}{"E"}=0.206; $par{"FsspSecMat"}{"E"}{"L"}=0.090;
$par{"FsspSecMat"}{"L"}{"H"}=0.128; $par{"FsspSecMat"}{"L"}{"E"}=0.090; $par{"FsspSecMat"}{"L"}{"L"}=0.237;

#random probabilities from unique subset of PDB
$par{"RandSecMat"}{"H"}{"H"}=0.132; $par{"RandSecMat"}{"H"}{"E"}=0.158; $par{"RandSecMat"}{"H"}{"L"}=0.302;
$par{"RandSecMat"}{"E"}{"H"}=0.158; $par{"RandSecMat"}{"E"}{"E"}=0.047; $par{"RandSecMat"}{"E"}{"L"}=0.182;
$par{"RandSecMat"}{"L"}{"H"}=0.302; $par{"RandSecMat"}{"L"}{"E"}=0.182; $par{"RandSecMat"}{"L"}{"L"}=0.176;

#substitution probabiliteis for accessibility from my head
$par{"FsspAccMat"}{"O"}{"O"}=0.5; $par{"FsspAccMat"}{"O"}{"B"}=0;
$par{"FsspAccMat"}{"B"}{"O"}=0; $par{"FsspAccMat"}{"B"}{"B"}=0.5;

#random probabilities for accessibility from my head
$par{"RandAccMat"}{"O"}{"O"}=0.25; $par{"RandAccMat"}{"O"}{"B"}=0.5;
$par{"RandAccMat"}{"B"}{"O"}=0.5; $par{"RandAccMat"}{"B"}{"B"}=0.25;

$h_nnconfusion{'H'}{'H'}=0.838; $h_nnconfusion{'H'}{'E'}=0.033; $h_nnconfusion{'H'}{'L'}=0.128;
$h_nnconfusion{'E'}{'H'}=0.068; $h_nnconfusion{'E'}{'E'}=0.754; $h_nnconfusion{'E'}{'L'}=0.178;
$h_nnconfusion{'L'}{'H'}=0.138; $h_nnconfusion{'L'}{'E'}=0.115; $h_nnconfusion{'L'}{'L'}=0.746;

$h_fsspsubs{'H'}{'H'}=0.825; $h_fsspsubs{'H'}{'E'}=0.013; $h_fsspsubs{'H'}{'L'}=0.162;
$h_fsspsubs{'E'}{'H'}=0.020; $h_fsspsubs{'E'}{'E'}=0.803; $h_fsspsubs{'E'}{'L'}=0.176;
$h_fsspsubs{'L'}{'H'}=0.184; $h_fsspsubs{'L'}{'E'}=0.129; $h_fsspsubs{'L'}{'L'}=0.687;

if($#ARGV < 0 || (grep /help/, @ARGV) ){
    print $scrName." : $scrGoal\n";
    print $help;
    exit;
}

@lg_Aminos=("V","L","I","M","F","W","Y","G","A","P","S","T","C","H","R","K","Q","E","N","D");
@lg_SS=("E","L","H");
@lg_SA=("B","O");
@lg_states=();
foreach $Amino (@lg_Aminos){
    foreach $SS (@lg_SS){
	foreach $SA (@lg_SA){
	    $state=$Amino.$SS.$SA;
	    push @lg_states, $state;
	    $state=sprintf "%7s", $state;
	    $states.=$state;
	}
    }
}
@MaxProfFields=("SeqNo","PDBNo","ChainID","AA","STRUCTURE","COLS","BP1","BP2","SHEETLABEL","ACC","NOCC","OPEN","ELONG","WEIGHT",@lg_states);
&ini;
if(! defined $dbg) { $dbg=0; }
foreach $file (keys %h_filesIn){
    print "working on: $file\n" if($dbg);
    ($Lok,$msg)=&convert($file);
    die "ERROR, $msg" if(! $Lok);
}

#================================================================================================
sub convert{
    my $sbr='convert';
    my ($fileIn)=@_;
    my (@data,@fields);
    my (%h_PosToField,%h_profile);
    my ($cmd,$ID,$NRES,$size);
    my $fh="FH".$sbr;
    #read psi profile
    $NRES=0;
    
    if($fileIn=~/\.gz$/){
	$cmd="gunzip -c $fileIn";
	open($fh,"$cmd |") ||
	    return(0,"ERROR failed to open $cmd, stopped");
    }else{
	open($fh,$fileIn) ||
	    return(0,"ERROR failed to open hsspFile=$hsspFile, stopped");
    }
   
    ($ID)=( $fileIn =~ /(\S+)\..*$/ );
    $ID=~s/^.*\///;
    die "$sbr: ID not defined (not read from fileIn=$fileIn), stopped"
	if (! defined $ID);
    if(! defined $h_SeqSecAcc{$ID} ){
	print "WARNING: $ID, SeqSecAcc not defined for ID=$ID, skipping\n";
	die "ERROR";
    }
    while(<$fh>){
	next if(/^\s*$/);
	next if(/^Last/);
	last if(/Lambda/);
	s/^\s*|\s*$//g;
	if(/A  R  N  D  C/){
	    @fields =split(/\s+/,$_);
	    $h_PosToField{0} ="SeqNo";
	    $h_PosToField{1} ="AA";
	    for $i (0 .. $#fields){
		$pos=$i +2;
		if($i <= 19){
		    $h_PosToField{$i+2} =$fields[$i]; 
		    print "h_PosToField{$pos} = $h_PosToField{$pos} here1\n"
			if($dbg);
		}
		else{ 
		    $h_PosToField{$pos} =$fields[$i]."_freq"; 
		    print "h_PosToField{$pos} = $h_PosToField{$pos} here2\n"
			if($dbg);
		}
	    }
	    $h_PosToField{$#fields +3} ="INFORM";
	    $h_PosToField{$#fields +4} ="WEIGHT";
	    $size=$#fields+4; #4 because SeqNo AA WEIGHT INFORMATION
	    die "ERROR: unexpected number of fields in header line:\n$_\n, in $fileIn, stopped" 
		if($size != 43);  #check number of fields 2 + 20 + 20 + 2 
	    next;
	}
	@data=split(/\s+/,$_);
	if($#data ne $size){ 
	    die "ERROR: too short a line, $#data vs $size in $fileIn:\n$_\n, stopped"; 
	}
	$NRES++;
	for $i (0 .. $#data){
	    $h_profile{$NRES}{ $h_PosToField{$i} } =$data[$i];
	}
		
	if($h_profile{$NRES}{'AA'} ne  $h_SeqSecAcc{$ID}{$NRES}{'AA'} ){
	    die "*** aminoacids not same $h_profile{$NRES}{'AA'} vs $h_SeqSecAcc{$ID}{$NRES}{AA}, NRES=$NRES, for $ID, stopped";
	}

	$h_profile{$NRES}{"PDBNo"}      =$h_profile{$NRES}{"SeqNo"};
	$h_profile{$NRES}{"STRUCTURE"}  =$h_SeqSecAcc{$ID}{$NRES}{'SS'};
	$h_profile{$NRES}{"COLS"}       ="";
	$h_profile{$NRES}{"BP1"}        =0;  
	$h_profile{$NRES}{"BP2"}        =0; 
	$h_profile{$NRES}{"ACC"}        =$h_SeqSecAcc{$ID}{$NRES}{'SA'};
	
	$SAmax   =$h_SAmax{ $h_profile{$NRES}{'AA'} };
	die "*** SAmax not defined for $h_profile{$NRES}{'AA'}, stopped" if(!defined $SAmax);
	if($SAmax > 0){
	    $SA1=$h_profile{$NRES}{"ACC"}/$SAmax * 100;
	}
	else{ 
	    $SA1=0; 
	    print "since SAmax zero for $h_profile{$NRES}{'AA'}, taking it to be burried\n";
	}
	if($SA1 > 15){ $SAS="O"; }
	else{ $SAS="B"; }
	$h_profile{$NRES}{"SAS"}        =$SAS;
	
	$h_profile{$NRES}{"NOCC"}       =0;
	$h_profile{$NRES}{"OPEN"}       =0;  
	$h_profile{$NRES}{"ELONG"}      =0;
	$h_profile{$NRES}{"SHEETLABEL"} ="";
	$h_profile{$NRES}{"ChainID"}    ="";
    }
    close $fh;
    
    #convert to maxhom profile
    #first use proper format
    foreach $Numb (keys %h_profile){
	$h_profile{$Numb}{"SeqNo"}     =sprintf "%6d", $h_profile{$Numb}{"SeqNo"};
	$h_profile{$Numb}{"SeqNo"}    .=" ";
	$h_profile{$Numb}{"PDBNo"}     =sprintf "%4d", $h_profile{$Numb}{"PDBNo"};
	$h_profile{$Numb}{"PDBNo"}    .=" ";
	$h_profile{$Numb}{"ChainID"}   =sprintf "%1s", $h_profile{$Numb}{"ChainID"};
	$h_profile{$Numb}{"ChainID"}   .=" ";
	$h_profile{$Numb}{"AA"}        =sprintf "%1s", $h_profile{$Numb}{"AA"};
	$h_profile{$Numb}{"AA"}       .="  ";
	$h_profile{$Numb}{"STRUCTURE"} =sprintf "%1s", $h_profile{$Numb}{"STRUCTURE"};
	$h_profile{$Numb}{"STRUCTURE"}.=" ";

	$h_profile{$Numb}{"COLS"}      =sprintf "%7s", $h_profile{$Numb}{"COLS"};
	$h_profile{$Numb}{"BP1"}       =sprintf "%4d", $h_profile{$Numb}{"BP1"};
	$h_profile{$Numb}{"BP2"}       =sprintf "%4d", $h_profile{$Numb}{"BP2"};
	$h_profile{$Numb}{"SHEETLABEL"}=sprintf "%1s", $h_profile{$Numb}{"SHEETLABEL"};       
   
	$h_profile{$Numb}{"ACC"}       =sprintf "%4d", $h_profile{$Numb}{"ACC"};
	$h_profile{$Numb}{"ACC"}      .=" ";
	$h_profile{$Numb}{"NOCC"}      =sprintf "%4d", $h_profile{$Numb}{"NOCC"};
	$h_profile{$Numb}{"NOCC"}     .=" ";
	
	$h_profile{$Numb}{"OPEN"}      =sprintf "%6.2f", $h_profile{$Numb}{"OPEN"};
	$h_profile{$Numb}{"ELONG"}     =sprintf "%6.2f", $h_profile{$Numb}{"ELONG"};
	$h_profile{$Numb}{"WEIGHT"}    =1;
	$h_profile{$Numb}{"WEIGHT"}    =sprintf "%7.2f", $h_profile{$Numb}{"WEIGHT"};
	
	#foreach $key1 (sort keys %h_SSSA_SSSA){
	#    foreach $key2 (sort keys %{ $h_SSSA_SSSA{$key1} }){
	#	foreach $key3 (sort keys %{ $h_SSSA_SSSA{$key1}{$key2} } ){
	#	    foreach $key4 (sort keys %{ $h_SSSA_SSSA{$key1}{$key2}{$key3} } ){
	#		print "$key1,$key2,$key3,$key4, $h_SSSA_SSSA{$key1}{$key2}{$key3}{$key4}\n";
	#	    }
	#	}
	#    }
	#}
	
	foreach $res ("V","L","I","M","F","W","Y","G","A","P","S","T","C","H","R","K","Q","E","N","D"){
	    foreach $SS ( @lg_SS ){
		foreach $SA ( @lg_SA ){
		    $state                =$res.$SS.$SA;
		    $SS1                  =$h_profile{$Numb}{"STRUCTURE"};
		    $SAS1                 =$h_profile{$Numb}{"SAS"};
		    
		    $SS=~s/\s//g; $SA=~s/\s//g; $SS1=~s/\s//g; $SAS1=~s/\s//g;
		    #print "SS1=$SS1, SA1=$SAS1, SS2=$SS, SA2=$SA, $h_SSSA_SSSA{$SS1}{$SAS1}{$SS}{$SA}\n";
		    $STRVAL =$h_SeqSecAcc{$ID}{$Numb}{'SSSA'}{$SS}{$SA};
		    die "ERROR $sbr: STRVAL not defined, stopped"
			if(! defined $STRVAL);
		    #$STRVAL =( $h_SSSA_SSSA{$SS1}{$SAS1}{$SS}{$SA} ) /10;
		    $SEQVAL =$h_profile{$Numb}{$res};
		    $RI_S   =$h_SeqSecAcc{$ID}{$Numb}{'RI_S'}/9;
		    $RI_A   =$h_SeqSecAcc{$ID}{$Numb}{'RI_A'}/9;
		    #$h_profile{$Numb}{$state}=
			#$SEQVAL* exp( $par{'steepness'} * $STRVAL );
			#$SEQVAL* exp( $par{'steepness'} * ($RI_S + $par{'RI_A_weight'} * $RI_A)/(1 + $par{'RI_A_weight'}) * $STRVAL );
		    $h_profile{$Numb}{$state}=
			(1-$par{'StrSeqMix'}) * $SEQVAL +
			$par{'StrSeqMix'} *$STRVAL;
		    $h_profile{$Numb}{$state} =
			sprintf "%8.3f", $h_profile{$Numb}{$state};
		}
	    }
	    $h_profile{$Numb}{$res}    =sprintf "%8.3f", $h_profile{$Numb}{$res};	  
	}
    }
    #print maxhom profile
    
    $fileOut=$ID.".sssa_profile";
    open(FHOUT,">".$fileOut) ||
	die "$sbr: failed to open fileOut=$fileOut for writing, stopped";
    $header=&get_header($ID,$NRES,$states);
    #print "HEADER\n$header\n-----------------\n";
    print FHOUT $header;
    foreach $Numb ( sort { $a <=> $b } keys %h_profile ){
	foreach $MaxProfField (@MaxProfFields){
	    print FHOUT $h_profile{$Numb}{$MaxProfField};
	}
	print FHOUT "\n";
    }
    print FHOUT "//\n";
    close FHOUT;
}
#=========================================================================================
#=========================================================================================
sub ini{
    my $sbr='ini';
    my (@l_filesIn);
    my ($rdbphd);
    foreach $arg (@ARGV){
	if($arg=~/strmat=(\S+)/)  { $strmat= $1; }
	elsif($arg=~/rdbphd=(\S+)/i) { $rdbphd= $1; }
	elsif(-e $arg)               { push @l_filesIn , $arg ; }
	else{ die "ERROR, fileIn=$arg not found, stopped"; }
    }
    #if(! defined $strmat){ $strmat="/home/dudek/prof_prof/mat/StrMat.metric"; }

    foreach $file ( @l_filesIn ){
	if( $file=~/^dbg|^debug/){ $dbg=1; next; }
	if($file =~ /\.list/){
	    open(FHLIST, $file) || 
		die "ERROR, did not open file=$file, stopped";
	    while(<FHLIST>){
		next if(/^\#|^\s*$/);
		s/\s//g;
		$h_filesIn{$_}=1;
	    }
	close FHLIST;
	}
	else{ $h_filesIn{$file}=1; }
    }
    
    if(! defined $rdbphd){ die "ERROR $sbr: argument rdbphd not defined, stopped"; }
    else{
	if($rdbphd !~ /\.list/){ @rdbphd=($rdbphd); }
	else{
	    open(FHRDBLIST,$rdbphd) ||
		die "ERROR $sbr: failed to open list file=$rdbphd, stopped";
	    while(<FHRDBLIST>){ 
		next if(/^\#|^\s*$/);
		s/\s//g;
		push @rdbphd, $_;
	    }
	}
    }
    
#read surface accessibility values
# max. Acc. in order of TRANS (VLIMFWYGAPSTCHRKQENDBZX!-.)
#  V   L   I   M   F   W   Y   G  A   P   S   T
# 142,164,169,188,197,227,222,84,106,136,130,142
#  C   H   R   K   Q   E   N   D   B   Z  X ! - .
# 135,184,248,205,198,194,157,163,157,194,0,0,0 0
    $h_SAmax{'V'}=142; $h_SAmax{'L'}=164; $h_SAmax{'I'}=169;
    $h_SAmax{'M'}=188; $h_SAmax{'F'}=197; $h_SAmax{'W'}=227;
    $h_SAmax{'Y'}=222; $h_SAmax{'G'}=84;  $h_SAmax{'A'}=106;
    $h_SAmax{'P'}=136; $h_SAmax{'S'}=130; $h_SAmax{'T'}=142;
    $h_SAmax{'C'}=135; $h_SAmax{'H'}=184; $h_SAmax{'R'}=248;
    $h_SAmax{'K'}=205; $h_SAmax{'Q'}=198; $h_SAmax{'E'}=194;
    $h_SAmax{'N'}=157; $h_SAmax{'D'}=163; 
    $h_SAmax{'B'}=157; $h_SAmax{'Z'}=194; $h_SAmax{'X'}=100000; #to make sure it is exposed


    my ($ct,$flow,$Max,$Min,$NNspan,$prob,$SSspan,$PredSS,$PredSAS,$randflow);
    my (@l_acc,%h_str2str);

    #define structure translation
    #STR_CLASSES(1)='EBAPMebapm'
    #STR_CLASSES(2)='L TCStclss'
    #STR_CLASSES(3)='HGIhgiiiii'
    
    $h_str2str{'E'}=$h_str2str{'B'}=$h_str2str{'A'}=$h_str2str{'P'}=$h_str2str{'M'}='E';
    $h_str2str{'L'}=$h_str2str{' '}=$h_str2str{'T'}=$h_str2str{'C'}=$h_str2str{'S'}='L';
    $h_str2str{'H'}=$h_str2str{'G'}=$h_str2str{'I'}='H';
    
    #this reads structure matrix into a global h_SSSA_SSSA hash 
    ($Lok)=&read_structure_matrix($strmat);
    die "ERROR $sbr: stopped" if(! $Lok);


    undef %h_SeqSecAcc; undef %h_aveRIs;
    foreach $rdb (@rdbphd){
	($Lok,$msg)=&read_rdbPhd_file($rdb,\%h_SeqSecAcc,\%h_aveRIs);
	die "ERROR $sbr: subroutine read_rdbPhd_file failed on file=$rdbphd, stopped"
	    if(! $Lok);
    }

    
    #get average values of reliabilities
    foreach $ID (sort keys %h_SeqSecAcc){
	$aveRI_S=$h_aveRIs{$ID}{'RI_S'}; $aveRI_S=$aveRI_S/9;
	$aveRI_A=$h_aveRIs{$ID}{'RI_A'}; $aveRI_A=$aveRI_A/9;
	#$tmp=$aveRI_S;
	#print "factor for $ID: $tmp   with aveRI_S=$aveRI_S\n";
	foreach $ResNumb (sort {$a <=> $b} keys %{ $h_SeqSecAcc{$ID} } ){
	    $PredSS  =$h_SeqSecAcc{$ID}{$ResNumb}{'SS'}; 
	    $PredSAS =$h_SeqSecAcc{$ID}{$ResNumb}{'SAS'}; 
	    $RI_S    =$h_SeqSecAcc{$ID}{$ResNumb}{'RI_S'};
	    $RI_A    =$h_SeqSecAcc{$ID}{$ResNumb}{'RI_A'};
	    
	    $RI_S=$RI_S/9; $RI_A=$RI_A/9;
	    foreach $SS2 ("H","L","E"){ #out profile SS state
		foreach $SA2 ("B","O"){ #out profile SA state
		    #$tmp=1 + $RI_S - $aveRI_S;
		    #$tmp=$aveRI_S/$par{'RI_S_ave_glob'} * $aveRI_A/$par{'RI_A_ave_glob'};
		    #$tmp=9 * $aveRI_S/$par{'RI_S_ave_glob'};
		    #$tmp=$aveRI_S;
		    $valLoc =$h_SSSA_SSSA{$PredSS}{$PredSAS}{$SS2}{$SA2};
		    
		    $h_SeqSecAcc{$ID}{$ResNumb}{'SSSA'}{$SS2}{$SA2}  =$valLoc;
		}
	    }
	}
    }
    #------------------------------------------------------------

    #here rescale neural network confidence between SSMIN and SSMAX
    if($par{'rescale_structure'} ){
	print "info: rescalling strucutral matrix\n";
	$SSspan=$par{'SSMAX'}-$par{'SSMIN'};
	$NNspan=0;
	foreach $ID (sort keys %h_SeqSecAcc){
	    $Min=100000; $Max=-100000;
	    foreach $ResNumb (sort {$a <=> $b} keys %{ $h_SeqSecAcc{$ID} } ){
		foreach $SS ("H","L","E"){
		    foreach $SA ("B","O"){
			$prob=$h_SeqSecAcc{$ID}{$ResNumb}{'SSSA'}{$SS}{$SA};
			if($prob < $Min)     { $Min=$prob; }
			elsif($prob > $Max)  { $Max=$prob; }
		    }
		}
	    }
	    $NNspan=$Max-$Min;
	    #print "info:ID=$ID\n";
	    #print "NNspan=$NNspan SSspan=$SSspan Min=$Min Max=$Max\n";
	    foreach $ResNumb (sort {$a <=> $b} keys %{ $h_SeqSecAcc{$ID} } ){
		#if($ResNumb < 5){ print "------------------------------------------\n"; }
		foreach $SS ("H","L","E"){
		    foreach $SA ("B","O"){
			$prob=$h_SeqSecAcc{$ID}{$ResNumb}{'SSSA'}{$SS}{$SA};
			$h_SeqSecAcc{$ID}{$ResNumb}{"SSSA"}{$SS}{$SA}=
			    ($prob - $Min) * $SSspan/$NNspan + $par{'SSMIN'};
		    }
		}
	    }
	}
    }
    #---------------------------------------------------------    
}
#==========================================================================================
#==========================================================================================
sub get_header{
    my $sbr='get_header';
    my ($ID,$NRES,$states)=@_;
    my ($header);

$header="****** MAXHOM-PROFILE WITH SECONDARY  STRUCTURE AND ACCESSIBILITY PROFILES (SS-SA) V1.0 ******
#
ID        : $ID
HEADER    :
COMPOUND  :
SOURCE    :
AUTHOR    :
NRES      :  $NRES
NCHAIN    :    1
SMIN      :   -4.00
SMAX      :   11.00
MAPLOW    :    0.00
MAPHIGH   :    0.00
METRIC    : Maxhom_Blosum_Topits_str
#==========================================================================================================================================================================================================
 SeqNo  PDBNo AA STRUCTURE BP1 BP2  ACC NOCC  OPEN ELONG  WEIGHT".$states."\n";
#
# SeqNo  PDBNo AA STRUCTURE BP1 BP2  ACC NOCC  OPEN ELONG  WEIGHT   V       L       I       M       F       W       Y       G       A       P       S       T       C       H       R       K       Q       E       N       D\n";
    return($header);
}
#===========================================================================================   
#========================================================================================
sub read_rdbPhd_file{
    my $sbr='read_rdbPhd_file';
    my ($fileIn,$hr_data,$hr_aveRIs)=@_;
    my (@data,@header);
    my ($aveRI_A,$aveRI_S,$AA,$Bave,$check,$ctRes,$header,$ID,$linesize,$No,
	$Oave,$OtE,$OtH,$OtL,$PACC,$PHEL,$RI_A,$RI_S,$SAS);
    my ($cmd,$Blhood,$Elhood,$Hlhood,$Llhood,$Olhood);
    my ($Ot0,$Ot1,$Ot2,$Ot3,$Ot4,$Ot5,$Ot6,$Ot7,$Ot8,$Ot9);
    my (%h_field2col,%h_col2field);
    my $fh="FH".$sbr;

    $aveRI_A=$aveRI_S=$ctRes=0;
    if($fileIn=~/\.gz$/){
	$cmd="gunzip -c $fileIn";
	open($fh,"$cmd |") ||
	    return(0,"ERROR failed to open $cmd, stopped");
    }else{
	open($fh,$fileIn) ||
	    return(0,"ERROR failed to open hsspFile=$hsspFile, stopped");
    }
    
    $ID=$fileIn; $ID=~s/^.*\///; $ID=~s/\..*$//;
    while(<$fh>){
	#if(/VALUE\s*PROT_ID\s*:\s*(\S+)/){ $ID=$1;}
	#if( /\#\s+PDBID\s+:\s*(\S+)/){ $ID=$1; }
	next if(/^\#|^\s*$/);
	die "ERROR $sbr: ID not found in file=$fileIn, stopped"
	    if(! defined $ID);
	s/\s*$//;
	s/^\s*//;
	if(/No\s*AA/){
	    $header=$_;
	    #$_=~s/\s*$//;
	    @header=split(/\t/,$_);
	    $linesize=$#header;
	    for $i (0 .. $#header){
		$h_col2field{$i}          =$header[$i];
		$h_field2col{$header[$i]} =$i;
	    }
	    next;
	}
	$ctRes++;
	@data=split(/\t/,$_);
	die "ERROR $sbr: incorrect number of fields in fileIn=$fileIn, stopped"
	    if($#data != $linesize);
	$No    =$data[ $h_field2col{"No"} ];
	$AA    =$data[ $h_field2col{"AA"} ];
	$PHEL  =$data[ $h_field2col{"PHEL"} ];
	$OtH   =$data[ $h_field2col{"OtH"} ];
	$OtE   =$data[ $h_field2col{"OtE"} ];
	$OtL   =$data[ $h_field2col{"OtL"} ];
	$PACC  =$data[ $h_field2col{"PACC"} ];
	$RI_S  =$data[ $h_field2col{"RI_S"} ];
	$RI_A  =$data[ $h_field2col{"RI_A"} ];
	$aveRI_S+=$RI_S; $aveRI_A+=$RI_A;
	#if($RI_S/9 ==0){
	#    print $header;
	#    print $_,"\n";
	#}

	$Ot0   =$data[ $h_field2col{"Ot0"} ];
	$Ot1   =$data[ $h_field2col{"Ot1"} ];
	$Ot2   =$data[ $h_field2col{"Ot2"} ];
	$Ot3   =$data[ $h_field2col{"Ot3"} ];
	$Ot4   =$data[ $h_field2col{"Ot4"} ];
	$Ot5   =$data[ $h_field2col{"Ot5"} ];
	$Ot6   =$data[ $h_field2col{"Ot6"} ];
	$Ot7   =$data[ $h_field2col{"Ot7"} ];
	$Ot8   =$data[ $h_field2col{"Ot8"} ];
	$Ot9   =$data[ $h_field2col{"Ot9"} ];
		
	$check=grep {! defined } ($No,$AA,$PHEL,$OtH,$OtE,$OtL,$PACC,$RI_S,$RI_A,$Ot0,$Ot1,$Ot2,$Ot3,$Ot4,$Ot5,$Ot6,$Ot7,$Ot8,$Ot9);
	die "did not find all the data in rdbPhd(Prof) file=$fileIn,\n$_\n stopped"
	    if($check > 0);

	$Hlhood=($OtH)/($OtH+$OtE+$OtL);
	$Elhood=($OtE)/($OtH+$OtE+$OtL);
	$Llhood=($OtL)/($OtH+$OtE+$OtL);	

	#if   ($PHEL eq 'H'){  $Hlhood=1; $Llhood=0; $Elhood=0; }
	#elsif($PHEL eq 'E'){  $Hlhood=0; $Llhood=0; $Elhood=1; }
	#elsif($PHEL eq 'L'){  $Hlhood=0; $Llhood=1; $Elhood=0; }
	#else { die "ERROR: unexpected value for PHEL=$PHEL, stopped"; }
	
	$Bave=($Ot0+$Ot1+$Ot2+$Ot3)/4;
	$Oave=($Ot4+$Ot5+$Ot6+$Ot7+$Ot8+$Ot9)/6;
	$Blhood=$Bave/($Bave + $Oave);
	$Olhood=$Oave/($Bave + $Oave);
	die "ERROR $sbr: h_data for No=$No already defined in ID=$ID file=$fileIn,\n$_\n stopped"
	    if( defined $$hr_data{$ID}{$No} );
	
	#if($PACC/$h_SAmax{$AA} > 0.15 )      { $Olhood=1; $Blhood=0; }
	#elsif($PACC/$h_SAmax{$AA} <= 0.15 )  { $Olhood=0; $Blhood=1; }
	#else { die "ERROR: unexpected value of relative ACC, stopped"; }
	
	if   ($PACC/$h_SAmax{$AA} > 0.15 )   { $SAS="O"; }
	elsif($PACC/$h_SAmax{$AA} <= 0.15 )  { $SAS="B"; }
	
	$$hr_data{$ID}{$No}{'AA'}    =$AA;
	$$hr_data{$ID}{$No}{'H'}     =$Hlhood;
	$$hr_data{$ID}{$No}{'E'}     =$Elhood;
	$$hr_data{$ID}{$No}{'L'}     =$Llhood;
	$$hr_data{$ID}{$No}{'B'}     =$Blhood;
	$$hr_data{$ID}{$No}{'O'}     =$Olhood;
	$$hr_data{$ID}{$No}{'SA'}    =$PACC;
	$$hr_data{$ID}{$No}{'SS'}    =$PHEL;
	$$hr_data{$ID}{$No}{'SAS'}   =$SAS;
	$$hr_data{$ID}{$No}{'RI_S'}  =$RI_S;
	$$hr_data{$ID}{$No}{'RI_A'}  =$RI_A;
	#if($ID eq "d1hzta_"){
	#    print "$ID--$No--$AA\n";
	#}
    }
    close $fh;
    $aveRI_S=$aveRI_S/$ctRes; $aveRI_A=$aveRI_A/$ctRes;
    #print "aveRI_S: $aveRI_S \t aveRI_A: $aveRI_A\n";
    $$hr_aveRIs{$ID}{'RI_S'}=$aveRI_S;
    $$hr_aveRIs{$ID}{'RI_A'}=$aveRI_A;
    return (1,"ok");
}
#===========================================================================================	
#===========================================================================================
sub read_structure_matrix{
    my $sbr='read_structure_matrix';
    my ($strmat)=@_;
    #here, read in structural exchange matrix values
#             Eb      Ee      Lb      Le      Hb      He
#     Eb      40      18       8     -19     -11     -32
#     Ee      18      50      -2       8     -38     -17
#     Lb       8      -2      30       9      -3     -20
#     Le     -19       8       9      28     -25      -2
#     Hb     -11     -38      -3     -25      40      12
#     He     -32     -17     -20      -2      12      42
#  
# FAC_STR=10
# with notation b -> B , e -> O
    my (@data,%h_fields,$SS1,$SS2,$SA1,$SA2);
    undef %h_SSSA_SSSA;
    open(FHIN,$strmat) ||
	die "*** failed to open strmat=$strmat, stopped";
    while(<FHIN>){
	next if(/^\#|^\s*$/);
	s/\s*$//;
	@data=split(/\s+/,$_);
	if(/^state/){
	    for $i (0 .. $#data){
		next if($data[$i] eq 'state');
		($SS2,$SA2)=split(//,$data[$i]);
		$h_fields{$i}{'SS'}=$SS2;
		$h_fields{$i}{'SA'}=$SA2;
	    }
	    next;
	}
	($SS1,$SA1)=split(//,$data[0]);
	for $i (1 .. $#data){
	    $SS2=$h_fields{$i}{'SS'};
	    $SA2=$h_fields{$i}{'SA'};
	    $h_SSSA_SSSA{$SS1}{$SA1}{$SS2}{$SA2}=$data[$i]/10 -0.1;
	    #print "$SS1,$SA1,$SS2,$SA2,  -> $data[$i] $h_SSSA_SSSA{$SS1}{$SA1}{$SS2}{$SA2}\n";
	}
    }
    close FHIN;
    return 1;
}
#================================================================================================








