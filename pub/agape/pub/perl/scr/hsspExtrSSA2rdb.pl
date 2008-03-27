#!/usr/bin/perl -w
##!/usr/sbin/perl -w
# 
# take list of hssp files (/data/hssp/1col.hssp_A
# extract seq and sec and acc into RDB
#
$[ =1 ;


#$ARGV[1]="xtmp.list";	#x.x
$par{"dirHssp"}=    "/data/hssp/";
$par{"extHssp"}=    ".hssp";
#$par{"nPerLine"}=   50;		# number of residues per row
#$par{"inclAcc"}=    100;	# include residues with rel Acc < this
#$par{"inclAccMode"}=">";	# (<=,<,>,>= mode of inclusion)

#$formatName="%-6s";
#$formatDes= "%-3s";

if ($#ARGV<1){
	print"goal:   extract seq, sec, and acc (and rel acc) into RDB\n";
	print"usage:  'script file_list_hssp' (1col.hssp_A, or: 1colA,1ppt, or: *hssp)\n";
	print"option: dirHssp=x\n";
	print"option: many (each will give one HSSP file, default: one big!)\n";
#	print"option: inclAcc=n inclAccMode=< (incl relative acc <n)\n";
	exit;}

$fileIn=$ARGV[1];@fileIn=("$fileIn");
$fhin="FHIN";$fhinHssp="FHIN_HSSP";$fhout="FHOUT";
$fileOut=$fileIn; 
$fileOut="OUT-"."$fileIn";$fileOut=~s/^.*\/|\..*$//g;$fileOut.=".rdb";
				# ------------------------------
$Lmany=0;			# command line options
foreach $arg(@ARGV){
    next if ($arg eq $ARGV[1]);
    if    ($arg =~ /^dirHssp=(.+)/)    {$par{"dirHssp"}=$1;}
    elsif ($arg eq  "many")            {$Lmany=1;}
#    elsif ($arg =~ /^inclAcc=(.+)/)    {$par{"inclAcc"}=$1;}
#    elsif ($arg =~ /^inclAccMode=(.+)/){$par{"inclAccMode"}=$1;}
    elsif (-e $arg)                    {push(@fileIn,$arg);}
    else  {print "*** option $arg not digested\n";
	   die;}}
				# ------------------------------
				# file or list of files?
if (($#fileIn==1) && &is_hssp_list($fileIn)){
    print "--- reading $fileIn (claimed to be list of HSSP files)\n";
    &open_file("$fhin", "$fileIn");$#fileIn=0;
    while (<$fhin>) {$_=~s/\n|\s//g;
		     $chain=$_; $chain=~s/^.*\.hssp//g;$chain=~s/^.*_(\w)$/$1/g; 
		     $file=$_;$file=~s/_\w$//g;
		     if (! -e $file && ($file !~ /^\//)){
			 $file=$par{"dirHssp"}.$file;}
		     if (! -e $file){print"-*- missing '$file'\n";
				     next;}
		     if (length($chain)>0){$file.="_$chain";}
		     push(@fileIn,$file);}close($fhin);}
elsif($fileIn=~/,/) {		# get list from comma delimited list
    $fileOut="OUT-extrSeqSec-".$$.".tmp";
    $#tmp=0;$fileIn=~s/^,*|,*$//g;@tmp=split(/,/,$fileIn);
    foreach $tmp (@tmp){
	$Lok=0;
	if ((length($tmp)>5)||(length($tmp)<4)){
	    print "*** to use the option '1pdbC,2dbxA' only pdb ids'(+chain)\n";
	    die;}
	if (length($tmp)==5){
	    $id=substr($tmp,1,4);$chain=substr($tmp,5,1);}
	else {
	    $id=$tmp;$chain="";}
	$file=$id.$par{"extHssp"};
	if (-e $file){
	    if (length($chain)>0){$file.="_".$chain;}
	    push(@fileIn,$file);$Lok=1;}
	next if ($Lok);
	if ($file !~/^\//){$file=$par{"dirHssp"}.$file;}
	if (-e $file){
	    if (length($chain)>0){$file.="_".$chain;}
	    push(@fileIn,$file);$Lok=1;}
	next if ($Lok);
	print "*-* missing hssp '$file'\n";}}

elsif ($#fileIn==1) {
    if (! -e $fileIn && ($file !~ /^\//)){
	$fileIn=$par{"dirHssp"}.$fileIn;}
    if (! -e $fileIn){print"-*- missing '$fileIn'\n";
		      die;}
    push(@fileIn,$fileIn);}
else {
    print "*** ERROR $0 no condition true to start with\n";
    exit;}
				# ------------------------------
				# read list of files
if (! $Lmany){
    &rdbWrtHdrHere;}
&exposure_normalise_prepare;	# initialise the normalisation of accessibility

foreach $fileIn (@fileIn){
    $chain=$fileIn; $chain=~s/^.*\.hssp//g;$chain=~s/^.*_(\w)$/$1/g; 
    $file=$fileIn;$file=~s/_\w$//g;$id=$file;$id=~s/^.*\///g;$id=~s/\.hssp.*$//g;
    ++$ct;
    if (length($chain)<1){$Lchain=0;}else{$Lchain=1;}
    if (! -e $file){$file=$par{"dirHssp"}.$file;}
    if (! -e $file){print "*** no hssp '$file'\n";
		    next;}
    if ($Lmany){$fileOut=$id.".rdb";
		$fileOut=~s/$id/$id$chain/ if $Lchain;
		&rdbWrtHdrHere;}
				# ------------------------------
				# read HSSP file
    print"--- reading '$file' ";if($Lchain){print" chain=$chain, ";}print"\n";
    if ( ! defined $chain || length($chain)==0 || $chain eq " "){
	$chainTmp="*";}
    else {$chainTmp=$chain;}

    &open_file("$fhinHssp", "$file");
    $fileRd[$ct]=$file; if ($Lchain){$fileRd[$ct].="_"."$chain";}
    while (<$fhinHssp>) { last if ($_=~/^ SeqNo/);
			  if ($_=~/^NALIGN\s+(\d+)/)   {$nali=$1;next;}
			  if ($_=~/^SEQLENGTH\s+(\d+)/){$len=$1;next;}}
    while (<$fhinHssp>) { 
	last if (/^\#\#/);
	next if ($Lchain && (substr($_,13,1) ne $chain));
				# filter accessibility
	$seq=substr($_,15,1);if ($seq eq " "){$seq="X";} elsif ($seq =~/[a-z]/){$seq="C";}
	$sec=&convert_sec(substr($_,18,1));
	$acc=substr($_,36,4);$acc=~s/\s//g;$aa= substr($_,15,1);
	$relAcc=&convert_acc($aa,$acc);
	&rdbWrtLineHere;
    }close($fhinHssp);
    close($fhout) if ($Lmany);
}
close($fhout) if (! $Lmany);

if (-e $fileOut){print "--- output in $fileOut\n";}
exit;



#==============================================================================
# library collected (begin) lll
#==============================================================================


#==============================================================================
sub convert_acc {
    local ($aa,$acc,$char,$mode) = @_ ;
    local (@tmp1,@tmp2,@tmp,$it,$tmpacc,$valreturn);
#--------------------------------------------------------------------------------
#    convert_acc                converts accessibility (acc) to relative acc
#                               default output is just relative percentage (char = 'unk')
#         in:                   AA, (one letter symbol), acc (Angstroem),char (unk or:
#                    note:      output is relative percentage, default if char empty or='unk'
#                                    ============
#                               char='15:100_b:e' -> returns symbols 
#                                    ============
#                                    b for relacc <15, e for relacc>=15
#                                    ===============
#                               char='4:15:100_b:i:e' -> returns symbols 
#                                    ===============
#                                    b for relacc <4, i: 4<=relacc<15, e for relacc>=15
#         in:                   .... $mode:
#                               mode=''=default, '3ang', '5ang', '07ang' -> different water
#                                    radius, 'RS' then X=0
#         out:                  converted (with return)
#--------------------------------------------------------------------------------

    &exposure_normalise_prepare($mode) if (! %NORM_EXP);
				# default (3 states)
    if ( ! defined $char || $char eq "unk") {
	$valreturn=  &exposure_normalise($acc,$aa);}
				# optional e.g. char='15:100_b:e'
    elsif ($char =~ /\d:\d/) {
	if (! %NORM_EXP ){print "*** ERROR in convert_acc: NORM_EXP empty \n*** please,",
			  print "    do initialise with exposure_normalise_prepare\n";
			  exit;}
	$tmpacc= &exposure_normalise($acc,$aa);

	@tmp=split(/_/,$char);@tmp1=split(/:/,$tmp[1]);@tmp2=split(/:/,$tmp[2]);
	if   ($tmpacc<$tmp1[1])      {
	    $valreturn=$tmp2[1];}
	elsif($tmpacc>=$tmp1[$#tmp1-1]){
	    $valreturn=$tmp2[$#tmp1];}
	else { 
	    for ($it=2;$it<$#tmp1;++$it) {
		if ( ($tmpacc>=$tmp1[$it-1]) && ($tmpacc<$tmp1[$it+1]) ) {
		    $valreturn=$tmp2[$it]; 
		    last; }}} }
    else {print "*** ERROR calling convert_acc (lib-br) \n";
	  print "***       acc=$acc, aa=$aa, char passed (eg. 15:100_b:4)=$char, not ok\n";
	  exit;}
    $valreturn=100 if ($valreturn>100);	# saturation (shouldnt happen, should it?)
    return $valreturn;
}				# end of convert_acc

#==============================================================================
sub convert_sec {
    local ($sec,$char) = @_ ;
#--------------------------------------------------------------------------------
#    convert_sec                converts 8 DSSP secondary str. into 3 (H,E,L)= default 
#                               char=HL    -> H=H,I,G  L=rest
#                               char=HELB  -> H=H,I,G  E=E, B=B, L=rest
#                               char=HELT  -> H=H,I,G  E=E,B  T=T, L=rest
#                               char=HELBT -> H=H,I,G  E=E, B=B, T=T, L=rest
#         default =             HEL
#         in:                   structure to convert
#         out:                  converted (with return)
#--------------------------------------------------------------------------------
				# default (3 states)
    if ( !defined $char || length($char)==0 || $char eq "HEL" || ! $char) {
	return "H" if ($sec=~/[HIG]/);
	return "E" if ($sec=~/[EB]/);
	return "L";}
				# optional
    elsif ($char eq "HL")    { return "H" if ($sec=~/[HIG]/);
			       return "L";}
    elsif ($char eq "HELT")  { return "H" if ($sec=~/[HIG]/);
			       return "E" if ($sec=~/[EB]/);
			       return "T" if ($sec=~/[T]/);
			       return "L";}
    elsif ($char eq "HELB")  { return "H" if ($sec=~/HIG/);
			       return "E" if ($sec=~/[E]/);
			       return "B" if ($sec=~/[B]/);
			       return "L";}
    elsif ($char eq "HELBT") { return "H" if ($sec=~/[HIG]/);
			       return "E" if ($sec=~/[EB]/);
			       return "B" if ($sec=~/[E]/);
			       return "T" if ($sec=~/[T]/);
			       return "L";}
    else { print "*** ERROR calling convert_sec (lib-br), sec=$sec, or char=$char, not ok\n";
	   return(0);}
}				# end of convert_sec

#==============================================================================
sub exposure_normalise {
    local ($exp_in, $aa_in) = @_;
    $[=1;
#----------------------------------------------------------------------
#   exposure_normalise          normalise DSSP accessibility with maximal values
#                               (taken from Schneider)
#----------------------------------------------------------------------
    if ( $aa_in !~ /[ABCDEFGHIKLMNPQRSTUVWXYZ]/ ) {
	if ( $aa_in=~/[!.]/ ) { $aa_in = "X"; }
	else { print "*** ERROR in exposure_normalise: aa passed wrong: '$aa_in' \n";
	       exit; }}

    if ($NORM_EXP{$aa_in}>0) { $exp_normalise= 100 * ($exp_in / $NORM_EXP{$aa_in});}
    else { print "*** \n*** exposure_normalise, division by zero:aa=$aa_in,acc=$exp_in,norm=",
	   $NORM_EXP{$aa_in},"\n***\n";
	   $exp_normalise=$exp_in/1.8; # ugly ...
	   if ($exp_normalise>100){$exp_normalise=100;}}
    return $exp_normalise;
}				# end of exposure_normalise

#==============================================================================
sub exposure_normalise_prepare {
    local ($mode) = @_;
    $[=1;
#----------------------------------------------------------------------
#    exposure_normalise_prepare normalisation weights (maximal: Schneider, Dipl)
#----------------------------------------------------------------------
#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    if ((!defined $mode)||(length($mode) <= 1)) {
	$NORM_EXP{"A"} =106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} =135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} =197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} =169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} =188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} =198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} =142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} =180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =222;  $NORM_EXP{"Z"} =196;         # E or Q

#   --------------------------------------------------
#   maximal 3 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /3ang/ ) {
	$NORM_EXP{"A"} =179;  $NORM_EXP{"B"} =255;         # D or N
	$NORM_EXP{"C"} = 99;  $NORM_EXP{"D"} =249;  $NORM_EXP{"E"} =279;
	$NORM_EXP{"F"} =199;  $NORM_EXP{"G"} =169;  $NORM_EXP{"H"} =219;
	$NORM_EXP{"I"} =189;  $NORM_EXP{"K"} =309;  $NORM_EXP{"L"} =209;
	$NORM_EXP{"M"} =189;  $NORM_EXP{"N"} =259;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} =259;  $NORM_EXP{"R"} =299;  $NORM_EXP{"S"} =209;
	$NORM_EXP{"T"} =209;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =239;
	$NORM_EXP{"X"} =200;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =239;  $NORM_EXP{"Z"} =269;         # E or Q

#   --------------------------------------------------
#   maximal 5 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /5ang/ ) {
	$NORM_EXP{"A"} =209;  $NORM_EXP{"B"} =295;         # D or N
	$NORM_EXP{"C"} =139;  $NORM_EXP{"D"} =289;  $NORM_EXP{"E"} =349;
	$NORM_EXP{"F"} =199;  $NORM_EXP{"G"} =219;  $NORM_EXP{"H"} =229;
	$NORM_EXP{"I"} =189;  $NORM_EXP{"K"} =399;  $NORM_EXP{"L"} =239;
	$NORM_EXP{"M"} =189;  $NORM_EXP{"N"} =299;  $NORM_EXP{"P"} =189;
	$NORM_EXP{"Q"} =309;  $NORM_EXP{"R"} =309;  $NORM_EXP{"S"} =259;
	$NORM_EXP{"T"} =239;  $NORM_EXP{"V"} =189;  $NORM_EXP{"W"} =259;
	$NORM_EXP{"X"} =230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =259;  $NORM_EXP{"Z"} =329;         # E or Q

#   --------------------------------------------------
#   maximal 0.7 Angstrom water
#   --------------------------------------------------
    } elsif ($mode =~ /07ang/ ) {
	$NORM_EXP{"A"} =119;  $NORM_EXP{"B"} =169;         # D or N
	$NORM_EXP{"C"} = 99;  $NORM_EXP{"D"} =169;  $NORM_EXP{"E"} =179;
	$NORM_EXP{"F"} =169;  $NORM_EXP{"G"} =109;  $NORM_EXP{"H"} =173;
	$NORM_EXP{"I"} =159;  $NORM_EXP{"K"} =206;  $NORM_EXP{"L"} =159;
	$NORM_EXP{"M"} =159;  $NORM_EXP{"N"} =169;  $NORM_EXP{"P"} =149;
	$NORM_EXP{"Q"} =169;  $NORM_EXP{"R"} =209;  $NORM_EXP{"S"} =139;
	$NORM_EXP{"T"} =149;  $NORM_EXP{"V"} =149;  $NORM_EXP{"W"} =169;
	$NORM_EXP{"X"} =230;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =189;  $NORM_EXP{"Z"} =175;         # E or Q

#   --------------------------------------------------
#   RS (X=0, from Reinhard
#   --------------------------------------------------
    } elsif ($mode =~/RS/) {
	$NORM_EXP{"A"} =106;  $NORM_EXP{"B"} =157;         # D or N
	$NORM_EXP{"C"} =135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} =197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} =169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} =188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} =198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} =142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} =180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =222;  $NORM_EXP{"Z"} =194;         # E or Q

#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    } else {
	$NORM_EXP{"A"} =106;  $NORM_EXP{"B"} =160;         # D or N
	$NORM_EXP{"C"} =135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
	$NORM_EXP{"F"} =197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
	$NORM_EXP{"I"} =169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
	$NORM_EXP{"M"} =188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
	$NORM_EXP{"Q"} =198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
	$NORM_EXP{"T"} =142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
	$NORM_EXP{"X"} =180;         # undetermined (deliberate)
	$NORM_EXP{"Y"} =222;  $NORM_EXP{"Z"} =196;         # E or Q
    }
}				# end of exposure_normalise_prepare 

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
# library collected (end)   lll
#==============================================================================


1;
#===============================================================================
sub rdbWrtHdrHere {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdbWrtHdr                       
#-------------------------------------------------------------------------------
    &open_file("$fhout", ">$fileOut");
    print $fhout "\# Perl-RDB\n","\# Extract from HSSP file(s)\n";
    print $fhout 
	"id","\t","chain","\t","len","\t","nali","\t",
	"seq","\t","sec","\t","acc","\t","rel","\n";
}				# end of rdbWrtHdrHere

#===============================================================================
sub rdbWrtLineHere {
    $[ =1 ;
#-------------------------------------------------------------------------------
#   rdbWrtLine                       
#-------------------------------------------------------------------------------
    printf $fhout 
	"%-s\t%-1s\t%4d\t%4d\t%1s\t%1s\t%4d\t%4d\n",
	$id,$chainTmp,$len,$nali,$seq,$sec,$acc,int($relAcc);
}				# end of rdbWrtLineHere

