#! /usr/bin/perl -w

$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="converts position specific scoring matrix given by -Q option of PSI-Blast into maxhom profile\n";

$help ="running instruction:\n";
$help.="$scrName MatrixFile (or list with suffix \".list\") filesec=\"name of ouput file of dsspExtrSeqSecAcc.pl\" strmat= \"structural exchange matrix\" \n";

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
    #die "ERROR, $msg" if(! $Lok);
    print "ERROR $msg\n" if(! $Lok);
}

#================================================================================================
sub convert{
    my $sbr='convert';
    my ($fileIn)=@_;
    my (@data,@fields);
    my (%h_PosToField,%h_profile);
    my ($ID,$NRES,$size,$miu);

    #read psi profile
    $NRES=0;
    open(FHFILEIN,$fileIn) || 
	die "$sbr: failed to open fileIn=$fileIn, stopped";
    ($ID)=( $fileIn =~ /(\S+)\..*$/ );
    $ID=~s/^.*\///;
    die "$sbr: ID not defined (not read from fileIn=$fileIn), stopped"
	if (! defined $ID);
    if(! defined $h_SeqSecAcc{$ID} ){
	die "ERROR: $sbr:  $ID, SeqSecAcc not defined in $filesec, stopped";
    }
    while(<FHFILEIN>){
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
	    return(0,"*** aminoacids not the same $h_profile{$NRES}{'AA'} vs $h_SeqSecAcc{$ID}{$NRES}{'AA'}, NRES=$NRES, for $ID, stopped");
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
    close FHFILEIN;
    
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
	#$weightLoc                     =$h_profile{$Numb}{"WEIGHT"} + 0.5;
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
		    $STRVAL =( $h_SSSA_SSSA{$SS1}{$SAS1}{$SS}{$SA} ) /10;
		    #$SEQVAL =$h_profile{$Numb}{$res} * $weightLoc;
		    $SEQVAL =$h_profile{$Numb}{$res};
		    
		    $miu=0.35;
		    $h_profile{$Numb}{$state}=$miu *$STRVAL + (1-$miu)*$SEQVAL;
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
    foreach $arg (@ARGV){
	if($arg=~/filesec=(\S+)/)    { $filesec=$1; }
	elsif($arg=~/strmat=(\S+)/)  { $strmat= $1; }
	elsif(-e $arg)               { push @l_filesIn , $arg ; }
	else{ die "ERROR, fileIn=$arg not found, stopped"; }
    }
    if(! defined $strmat){ $strmat="/ahome/dudek/prof_prof/mat/StrMat.metric"; }

    foreach $file ( @l_filesIn ){
	if( $file=~/^dbg|^debug/){ $dbg=1; next; }
	if($file =~ /\.list$/){
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
    my ($acc,$acclen,$ct,$sec,$seclen,$seq,$seqlen);
    my (@l_acc,%h_str2str);

    #define structure translation
    #STR_CLASSES(1)='EBAPMebapm'
    #STR_CLASSES(2)='L TCStclss'
    #STR_CLASSES(3)='HGIhgiiiii'
    
    $h_str2str{'E'}=$h_str2str{'B'}=$h_str2str{'A'}=$h_str2str{'P'}=$h_str2str{'M'}='E';
    $h_str2str{'L'}=$h_str2str{' '}=$h_str2str{'T'}=$h_str2str{'C'}=$h_str2str{'S'}='L';
    $h_str2str{'H'}=$h_str2str{'G'}=$h_str2str{'I'}='H';

    open(FHIN,$filesec) || 
	die "*** failed to open filesec=$filesec, stopped";
    while(<FHIN>){
	next if(/^\s*$/);
	next if(/^id/);
	s/\s*$//;
	($id,$len,$seq,$sec,$acc)=split(/\t/,$_);
	$id=~s/\s//g;
	$acc=~s/\,$//;       #$acc=~s/^\s*|\s*$//g;
	$seq=~tr[a-z][A-Z];  #$seq=~s/^\s*|\s*$//g;
	$sec=~tr[a-z][A-Z];  #$sec=~s/^\s*|\s*$//g;
	@l_acc=split(/\,/,$acc);
	@l_seq=split(//,$seq);
	@l_sec=split(//,$sec);
	foreach $it (@l_sec){
	    $it=$h_str2str{$it}; 
	    die "*** str2str not defined for $it, stopped"
		if(! defined $it);
	}
	
	$seqlen=length($seq);
	$seclen=length($sec);
	$acclen=$#l_acc+1;
	if (   $seqlen != $seclen ||
	       $len    != $seclen ||
	       $acclen != $seclen
	       ){
	    #print "seqlen=$seqlen seclen=$seclen acclen=$acclen len=$len\n";
	    die "*** equivalent lengths not equel in record:\n$_\n stopped";
	}
	if( defined $h_SeqSecAcc{$id}){ 
	    die "*** Seq Sec Acc already defined for $id, stopped";
	}
        for $i (0 .. $#l_seq){
	    $h_SeqSecAcc{$id}{$i+1}{'AA'}=shift(@l_seq);
	    $h_SeqSecAcc{$id}{$i+1}{'SS'}=shift(@l_sec);
	    $h_SeqSecAcc{$id}{$i+1}{'SA'}=shift(@l_acc);
	}
    }
    
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
	    $h_SSSA_SSSA{$SS1}{$SA1}{$SS2}{$SA2}=$data[$i];
	    #print "$SS1,$SA1,$SS2,$SA2,  -> $data[$i] $h_SSSA_SSSA{$SS1}{$SA1}{$SS2}{$SA2}\n";
	}
    }
    close FHIN;

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
    $h_SAmax{'B'}=157; $h_SAmax{'Z'}=194; $h_SAmax{'X'}=0;
    
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









