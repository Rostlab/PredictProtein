#!/usr/bin/perl -w
##!/usr/sbin/perl -w
# 
# take list of hssp files (/data/hssp/1col.hssp_A
# extract seq and sec str into rows of 100
#
$[ =1 ;

$par{"dirHssp"}=    "/home/rost/data/hssp/";
$par{"extHssp"}=    ".hssp";
$par{"nPerLine"}=    50;	# number of residues per row

$par{"inclSec"}=    100;	# include residues with %HE>0
$par{"inclType"}=   "HE";	# include residues with %HE>0
$par{"inclAcc"}=    100;	# include residues with rel Acc < this
$par{"inclMode"}=   "le";	# (<=,<,>,>= mode of inclusion)

$par{"minLen"}=      30;	# excluded if shorter

$par{"doStat"}=       0;	# compile per residue/ per sec str statistics
$par{"doConvert"}=    1;	# convert DSSP to 'HELT'

$par{"wrtNum"}=       1;	# write numbering of residues
$par{"wrtSeq"}=       1;	# write sequence
$par{"wrtLen"}=       1;	# write separate row with length and id

@kwd=sort (keys %par);

$formatName="%-6s";
$formatDes= "%-3s";

if ($#ARGV<1){
	print "goal:   extract seq and sec str into rows of 50\n";
	print "use:    'script file_list_hssp' (1col.hssp_A, or: 1colA,1ppt, or: *hssp)\n";
	print "opt:    nPerLine=50 (or line=50), dirHssp=x\n";
	print "        inclSec=<H|E|HE|T><gt|ge|le|lt>X         (include prot if e.g. \%H <..> X \n";
	print "NOTE:   ---> on overall secondary structure composition (PERCENTAGE!)\n";
	print "        inclAcc=<gt|ge|le|lt>X                   (include relAcc if <gt|ge|le|lt> X\n";
	print "NOTE:   ---> on each residue accessibility\n";
	print "        stat                   (do statistics)\n";
	print "        fileOut=x\n";
	print "        minLen=",$par{"minLen"},"      (minimal length to include)\n";
	print "        convert -> will convert to HELT\n";
	print "        noseq   -> will NOT write sequence\n";
	print "        nonum   -> will NOT write residue numbers\n";
	print "        nolen   -> will NOT write row with protein name and length\n";
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

$fileIn=$ARGV[1];@fileIn=("$fileIn");
$fhin="FHIN";$fhinHssp="FHIN_HSSP";$fhout="FHOUT";
$fileOut=$fileIn; 
$fileOut="OUT-"."$fileIn";$fileOut=~s/^.*\/|\..*$//g;$fileOut.=".txt";
				# ------------------------------
				# command line options
foreach $arg(@ARGV){
    next if ($arg eq $ARGV[1]);
    if    ($arg =~ /^dirHssp=(.+)/)    {$par{"dirHssp"}=    $1;}
    elsif ($arg =~ /^nPerLine=(.+)/)   {$par{"nPerLine"}=   $1;}
    elsif ($arg =~ /^line=(.+)/)       {$par{"nPerLine"}=   $1;}
    elsif ($arg =~ /^inclAcc=(.+)/)    {$par{"inclAcc"}=    $1; $par{"inclAcc"}=~s/(ge|gt|le|lt)//;
					$par{"inclMode"}=   $1; }
    elsif ($arg =~ /^inclSec=(.+)/)    {$par{"inclSec"}=    $1; $par{"inclSec"}=~s/(HE|H|E|T)(ge|gt|le|lt)//;
					$par{"inclType"}=   $1; 
					$par{"inclMode"}=   $2; }
					
    elsif ($arg =~ /^fileOut=(.+)/)    {$fileOut=           $1;}
    elsif ($arg =~ /^stat$/)           {$par{"doStat"}=     1;}
    elsif ($arg =~ /^conv[a-z]*$/i)    {$par{"doConvert"}=  1;}
    elsif ($arg =~ /^noseq*$/i)        {$par{"wrtSeq"}=     0;}
    elsif ($arg =~ /^nonum*$/i)        {$par{"wrtNum"}=     0;}
    elsif ($arg =~ /^nolen*$/i)        {$par{"wrtLen"}=     0;}
    elsif (-e $arg || -l $arg)         {push(@fileIn,$arg);}
    
    else  {
	$Lok=0; 
	if (defined %par && $#kwd>0) { 
	    foreach $kwd (@kwd){ 
		if ($arg =~ /^$kwd=(.+)$/){$Lok=1;$par{$kwd}=$1;
					   last;}}}
	if (! $Lok){ print "*** wrong command line arg '$arg'\n";
		     exit;
		     die;}}}

$#resId=$#resSeq=$#resSec=0;
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
elsif ($#fileIn>1) {
    $fileIn=$fileIn[1];
    if (! -e $fileIn && ($file !~ /^\//)){
	$#tmp=0;
	foreach $file (@fileIn){
	    $file=$par{"dirHssp"}.$file;
	    if (! -e $file && ! -l $file){
		print"-*- missing '$fileIn'\n";
		die;}
	    push(@tmp,$file);
	}
	@fileIn=@tmp;}}
else {
    print "*** ERROR $0 no condition true to start with\n";
    exit;}

$timeBeg=     time;		# date and time

				# ------------------------------
				# read list of files
$ctfile=0; $nfileIn=$#fileIn; 
foreach $fileIn (@fileIn){
    $chain=$fileIn; $chain=~s/^.*\.hssp//g;$chain=~s/^.*_(\w)$/$1/g; 
    $file=$fileIn;$file=~s/_\w$//g;$id=$file;$id=~s/^.*\///g;$id=~s/\.hssp.*$//g;
    ++$ct;
    if (length($chain)<1){$Lchain=0;}else{$Lchain=1;}
    if (! -e $file){$file=$par{"dirHssp"}.$file;}
    if (! -e $file){print "*** no hssp '$file'\n";
		    next;}
    ++$ctfile;
				# ------------------------------
				# estimate time
    $estimate=
	&fctRunTimeLeft($timeBeg,$nfileIn,$ctfile);
    $estimate="?"               if ($ctfile < 5);
    printf 
	"--- reading %-40s %4d (%4.1f%-1s), time left=%-s\n",
	$fileIn,$ctfile,(100*$ctfile/$nfileIn),"%",$estimate;

				# ------------------------------
				# read HSSP file
    &open_file("$fhinHssp", "$file");
    $fileRd[$ct]=$file; if ($Lchain){$fileRd[$ct].="_"."$chain";}
    while (<$fhinHssp>) { last if (/^ SeqNo/);}
    $sec=$seq="";
    while (<$fhinHssp>) { 
	if ($Lchain){$chainRd=substr($_,13,1);
		     if ($chainRd ne $chain){
			 last;}}
	last if (/^\#\#/);
				# ------------------------------
				# filter accessibility
	if ($par{"inclAcc"} != 100){
	    $Lincl=0;
	    $acc=substr($_,36,4);$acc=~s/\s//g;$aa= substr($_,15,1);
	    $relAcc=&convert_acc($aa,$acc);
	    if ((($par{"inclAccMode"} eq "lt")  && ($relAcc <  $par{"inclAcc"}))||
		(($par{"inclAccMode"} eq "le")  && ($relAcc <= $par{"inclAcc"}))||
		(($par{"inclAccMode"} eq "gt")  && ($relAcc >  $par{"inclAcc"}))||
		(($par{"inclAccMode"} eq "ge")  && ($relAcc >= $par{"inclAcc"}))){
		$Lincl=1;}}
	else{
	    $Lincl=1;}
	next if (! $Lincl);
	$seq.=substr($_,15,1);
	$sec.=substr($_,18,1);
    }close($fhinHssp);

				# skip strange
    next if (length($seq) < 1 || length($sec) < 1);
    next if ($par{"minLen"} && length($seq) < $par{"minLen"});

				# ------------------------------
				# check composition
    $Lincl=1;
    if ($par{"inclSec"} != 100) {
	$len=length($seq);
	$comH=$sec; $comH=~s/[^HG]//g;
	$comE=$sec; $comE=~s/[^EB]//g;
	$comT=$sec; $comT=~s/[^T]//g;
	$comHE=$comH.$comE;

	$lenCom=length($comHE) if ($par{"inclType"} eq "HE");
	$lenCom=length($comH)  if ($par{"inclType"} eq "H");
	$lenCom=length($comE)  if ($par{"inclType"} eq "E");
	$lenCom=length($comT)  if ($par{"inclType"} eq "T");
	$compo=    int(100*($lenCom/$len)); 

	$Lincl=0;
	$Lincl=1            if ($par{"inclMode"} eq "ge"  &&  $compo >= $par{"inclSec"});
	$Lincl=1            if ($par{"inclMode"} eq "gt"  &&  $compo >  $par{"inclSec"});
	$Lincl=1            if ($par{"inclMode"} eq "le"  &&  $compo <= $par{"inclSec"});
	$Lincl=1            if ($par{"inclMode"} eq "lt"  &&  $compo <  $par{"inclSec"}); }

				# skip due to composition
    if (! $Lincl) {
	print 
	    "--- \t $id skipped due to composition (",$par{"inclType"},"=$compo ",
	    $par{"inclMode"}," ",$par{"inclSec"},") \n";
	next; }

				# ------------------------------
				# store
    $id.="$chain"            if ($Lchain);
    push(@resId,$id); push(@resSeq,$seq); push(@resSec,$sec);
}
				# --------------------------------------------------
				# write output
@fh=("$fhout","STDOUT");
foreach $fh (@fh){
    &open_file("$fh", ">$fileOut") if ($fh ne "STDOUT");
    foreach $it (1..$#resId){
	printf $fh "$formatName $formatDes %6d\n",$resId[$it],"LEN",length($resSeq[$it])
	    if ($par{"wrtLen"});

	for ($itRes=1;$itRes<=length($resSeq[$it]);$itRes+=$par{"nPerLine"}){
				# get substrings:

				# numbers
	    if ($par{"wrtNum"}){
		$points=&myprt_npoints($par{"nPerLine"},$itRes);
		printf $fh "$formatName $formatDes %-s\n",$resId[$it]," ",$points; }
				# sequence
	    if ($par{"wrtSeq"}){
		$seq=substr($resSeq[$it],$itRes,$par{"nPerLine"});
		printf $fh "$formatName $formatDes %-s\n",$resId[$it],"SEQ",$seq;}
				# secondary structure
	    $sec=substr($resSec[$it],$itRes,$par{"nPerLine"});
	    if ($par{"doConvert"}){
		$tmp="";
		foreach $it (1..length($sec)){
		    $tmp.=&convert_sec(substr($sec,$it,1),"HELT");
		}
		$sec=$tmp;}
				# write
	    printf $fh "$formatName $formatDes %-s\n",$resId[$it],"SEC",$sec;}}
    if ($fh ne "STDOUT"){close($fh);}}
$fileOutId="ID".$fileOut;
&open_file("$fhout", ">$fileOutId");
foreach $id (@resId){
    print $fhout "$id\n";
}
close($fhout);
unlink($fileOutId) if ($#resId < 1);

				# ------------------------------
				# do per residue statistics
if ($par{"doStat"}){
    foreach $it (1..$#resId){
	$seq=$resSeq[$it];
	$seq=~s/[a-z]/C/g;
	($Lok,$msg,$sec)=
	    &convert_secFine($resSec[$it],"HELT");
	if (! $Lok){
	    print "*** $0 failed to convert_secFine on it=$it, sec=$resSec[$it],\n",$msg,"\n";
	    die;}
	@seq=split(//,$seq);
	@sec=split(//,$sec);
	foreach $mue (1..$#seq) {
	    if (! defined $ct{"seq","$seq[$mue]"}){push(@aa, $seq[$mue]);
						   $ct{"seq","$seq[$mue]"}=0;}
	    if (! defined $ct{"sec","$sec[$mue]"}){push(@ss, $sec[$mue]);
						   $ct{"sec","$sec[$mue]"}=0;}
	    $ct{"$seq[$mue]","$sec[$mue]"}=0     if (! defined $ct{"$seq[$mue]","$sec[$mue]"});
	    ++$ct{"seq","$seq[$mue]"};
	    ++$ct{"sec","$sec[$mue]"};
	    ++$ct{"$seq[$mue]","$sec[$mue]"}; }}
    $sumSeq=0;
    foreach $aa (@aa){
	$sumSeq+=$ct{"seq",$aa};}
    $sumSec=0;
    foreach $ss (@ss){
	$sumSec+=$ct{"sec",$ss};}
    @ss=("H","E","T","L");
    $#tmp=$#tmp2=0;
    foreach $aa (@aa){
	if ($aa=~/[ACDEFGHIKLMNPQRSTVWY]/){
	    $tmp{$aa}=1;}
	else {
	    push(@tmp2,$aa);} }

    @aa2=split(//,"VLIMFWYGAPSTCHRKQEND");
    foreach $aa (@aa2) {
	next if (! defined $tmp{$aa});
	push(@tmp,$aa); }
    $#aa=0;
    push(@aa,@tmp2,@tmp);
				# --------------------------------------------------
				# compile log odds
				# simple Fano info (fano)
				# I (S;R) = log [ ( f(S,R) / f(R) ) / (f(S) / N) ]
				# 
				# where f= counts, S=state, R=residue, N=total count
				# 
				# info difference (robson)
				# I (DelS;R)=I(S;R)-I(!S;R)= 
				#       log [ f(S,R)/f(!S,R) ] + log [ f(!S)/f(S) ]
				# --------------------------------------------------
    $ct{"R"}=join(',',@aa);
    $ct{"S"}=join(',',@ss);
    $sep=" ";
    $Lnum=$Lperc=$Lfano=$Lrobson=$Lbayes=1;

    ($Lok,$msg,$tmpWrt)=
	&stat2DarrayWrt($sep,$Lnum,$Lperc,$Lfano,$Lrobson,$Lbayes,%ct);
				# ------------------------------
				# screen
    print "--- ","-" x 60,"\n";
    print "--- statistics:\n";
    print $tmpWrt;
    print "--- \n";
    print "--- sumSeq=$sumSeq, sumSec=$sumSec\n";
				# ------------------------------
				# file

    $fileOut2="stat-".$fileOut;
    &open_file("$fhout", ">$fileOut2");
    print $fhout $tmpWrt; 
    close($fhout);
}

print "--- output     in $fileOut\n"   if (-e $fileOut);
print "--- taken         ",$#resId,"\n";
print "---         id in $fileOutId\n" if (-e $fileOutId);
print "--- statistics in $fileOut2\n" if (defined $fileOut2 && -e $fileOut2);

exit;


#==============================================================================
# library collected (begin) lll
#==============================================================================


#===============================================================================
sub complete_dir { local($DIR)=@_; $[=1 ; 
		   return(0) if (! defined $DIR);
		   return($DIR) if ($DIR =~/\/$/);
		   return($DIR."/");} # end of complete_dir

#===============================================================================
sub completeDir  { local($DIR)=@_; $[=1 ; 
		   return(0) if (! defined $DIR);
		   return($DIR) if ($DIR =~/\/$/);
		   return($DIR."/");} # end of completeDir

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

#===============================================================================
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
sub convert_secFine {
    local ($sec,$char) = @_ ;
#--------------------------------------------------------------------------------
#    convert_secFine            takes an entire string ('HEL') and fine-tunes: ' EHH'-> '  HH'
#                               char=HL    -> H=H,I,G  L=rest
#                               char=EL    -> E=E,B    L=rest
#                               char=TL    -> T=T, single B  L=rest
#                               char=HELB  -> H=H,I,G  E=E, B=B, L=rest
#                               char=HELT  -> H=H,I,G  E=E,B  T=T, L=rest
#                               char=HELBT -> H=H,I,G  E=E, B=B, T=T, L=rest
#         default =             HEL
#         in:                   structure-string to convert
#         out:                  (1|0,$msg,converted)
#--------------------------------------------------------------------------------
    $sbrName="lib-prot:"."convert_secFine";
				# default
    $char="HEL"                 if (! defined $char || ! $char);
				# unused
    if    ($char eq "HL")     { $sec=~s/[IG]/H/g;  $sec=~s/[EBTS !]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "EL")     { $sec=~s/[EB]/E/g;  $sec=~s/[HIGTS !]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "TL")     { $sec=~s/[^B]B[^B]/T/g; 
				$sec=~s/[^T]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "HEL")    { $sec=~s/[IG]/H/g;  $sec=~s/[TS !]/L/g;
				$sec=~s/B/E/g;
				$sec=~s/LEH/LLH/g; $sec=~s/HEL/HLL/g; # <-- fine
				return(1,"ok",$sec); }
    elsif ($char eq "HELT")   { $sec=~s/[IG]/H/g;  $sec=~s/[S !]/L/g;
				$sec=~s/B/E/g;
				$sec=~s/LEH/LLH/g; $sec=~s/HEL/HLL/g; # <-- fine
				return(1,"ok",$sec); }
    elsif ($char eq "HELB")   { $sec=~s/[IG]/H/g;  $sec=~s/[TS !]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "HELBT")  { $sec=~s/[IG]/H/g;  $sec=~s/[S !]/L/g;
				return(1,"ok",$sec); }
    elsif ($char eq "Hcap")   { $sec=~s/[IG]/H/g;
				$sec=~s/[^H]HH[^H]/LLLL/g;    # too short (< 3)
				$sec=~s/^HH[^H]/LLL/g;        # too short (< 3)
				$sec=~s/[^H]HH$/LLL/g;        # too short (< 3)
				$sec=~s/[^H]H(H+)/Ln$1/g;     # N-cap -> 'n'
				$sec=~s/([nH]H+)H[^H]/$1cL/g; # C-cap -> 'c'
				$sec=~s/[^ncH]/L/g;           # others -> L
				$sec=~s/(Hc)(L+)c/$1$2u/g;    # correct 'cLLc'
				$sec=~s/n(L+n)/u$1/g;         # correct 'nLLn'
				return(1,"ok",$sec); }
    elsif ($char eq "Ecap")   { $sec=~s/B/E/g;
				$sec=~s/[^E]E[^E]/LLL/g;      # too short (< 2)
				$sec=~s/^E[^E]/LL/g;          # too short (< 2)
				$sec=~s/[^E]E$/LL/g;          # too short (< 2)
				$sec=~s/[^E]E(E+)/Ln$1/g;     # N-cap -> 'n'
				$sec=~s/([nE]E*)E[^E]/$1cL/g; # C-cap -> 'c'
				$sec=~s/[^ncE]/L/g;           # others -> L
				$sec=~s/(Ec)(L+)c/$1$2u/g;    # correct 'cLLc'
				$sec=~s/n(L+n)/u$1/g;         # correct 'nLLn'
				return(1,"ok",$sec); }
    elsif ($char eq "HEcap")  { $sec=~s/B/E/g;
				$sec=~s/[IG]/H/g;
				$sec=~s/[^HE]/L/g;               # nonH, nonE -> L

				$sec=~s/([^H])HH([^H])/$1LL$2/g; # too short (< 3)
				$sec=~s/^HH([^H])/LL$1/g;        # too short (< 3)
				$sec=~s/([^H])HH$/$1LL/g;        # too short (< 3)

				$sec=~s/([^E])E([^E])/$1L$2/g;   # too short (< 2)
				$sec=~s/^E([^E])/L$1/g;          # too short (< 2)
				$sec=~s/([^E])E$/$1L/g;          # too short (< 2)

				$sec=~s/([^H])H(H+)/$1n$2/g;     # N-cap H -> 'n'
				$sec=~s/([nH]H+)H([^H])/$1c$2/g; # C-cap H -> 'c'

				$sec=~s/([^E])E(E+)/$1n$2/g;     # N-cap E -> 'n'
				$sec=~s/([nE]E*)E([^E])/$1c$2/g; # C-cap E -> 'c'

				$sec=~s/([EH]c)(L+)c/$1$2u/g;    # correct 'cLLc'
				$sec=~s/n(L+n)/u$1/g;            # correct 'nLLn'
				return(1,"ok",$sec); }
    else { 
	return(&errSbr("char=$char, not recognised\n")); }
}				# end of convert_secFine

#==============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#==============================================================================
sub errSbrMsg {local($txtInLoc,$msgInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbrMsg                   simply writes '*** ERROR $sbrName: $txtInLoc\n'.$msg
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       $msgInLoc.="\n";
	       $msgInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc".$msgInLoc);
}				# end of errSbrMsg

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
sub fctRunTimeLeft {
    local($timeBegLoc,$num_to_run,$num_did_run) = @_ ;
    local($sbrName);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctRunTimeLeft              estimates the time the job still needs to run
#       in:                     $timeBegLoc : time (time) when job began
#       in:                     $num_to_run : number of things to do
#       in:                     $num_did_run: number of things that are done, so far
#       out:                    $_string_time-still (hour:min:sec)
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."fctRunTimeLeft";

    $timeNow=time;
    $timeRun=$timeNow-$timeBegLoc;

    $percLoc=0;
    $percLoc=100*($num_did_run/$num_to_run) if ($num_to_run > 0);

    if ($percLoc) {
	$timeTot=int(100*($timeRun/$percLoc));
	$timeLeft=$timeTot-$timeRun;
	$tmp=
	    &fctSeconds2time($timeLeft); 
	@tmp=split(/:/,$tmp); foreach $tmp (@tmp){$tmp=~s/^0//g;}
	$estimateLoc= "";
	$estimateLoc.=    $tmp[1]."h " if ($tmp[1] > 9);
	$estimateLoc.=" ".$tmp[1]."h " if (9 >= $tmp[1] && $tmp[1] > 0);
	$estimateLoc.=    $tmp[2]."m " if ($tmp[2] > 9);
	$estimateLoc.=" ".$tmp[2]."m " if (9 >= $tmp[2] && $tmp[2] > 0);
	$estimateLoc.=" "." ".    "  " if ($tmp[2] <= 0 && $tmp[1] > 0);
	$estimateLoc.=    $tmp[3]."s " if ($tmp[3] > 9);
	$estimateLoc.=" ".$tmp[3]."s " if (9 >= $tmp[3] && $tmp[3] > 0);
	$estimateLoc.=" "." ".    "  " if ($tmp[3] <= 0 && ($tmp[1] > 0 || $tmp[2] > 0));
	$estimateLoc= "done"        if (length($estimateLoc) < 1);}
    else {
	$estimateLoc="?";}
    return($estimateLoc);
}				# end of fctRunTimeLeft

#==============================================================================
sub fctSeconds2time {
    local($secIn) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   fctSeconds2time             converts seconds to hours:minutes:seconds
#       in:                     seconds
#       out:                    05:13:50
#-------------------------------------------------------------------------------
    $sbrName="lib-comp:"."fctSeconds2time";$fhinLoc="FHIN"."$sbrName";
    $minTmp=  int($secIn/60);
    $seconds= ($secIn - $minTmp*60); $seconds=int($seconds);
    $hours=   int($minTmp/60);       $hours=  int($hours);
    $minutes= ($minTmp - $hours*60); $minutes=int($minutes);

    $seconds="0".$seconds if (length($seconds)==1);
    $minutes="0".$minutes if (length($minutes)==1);
    $hours=  "0".$hours   if (length($hours)==1);
    return("$hours".":".$minutes.":".$seconds);
}				# end of fctSeconds2time

#==============================================================================
sub funcInfoConditional {
    local($Lfano,$Lrobson,$Lbayes,%tmpLoc) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   funcInfoConditional         Fano information
#                               R. Fano, Transmission of information, Wiley, New York, 1961
#                               S= state
#                               R= residue (feature)
#                               f= counts
#                               N= total number of residues, counts
#                               I (S;R) = log [ ( f(S,R) / f(R) ) / (f(S) / N) ]
#                               information difference:
#                               B. Robson, Biochem J., 141, 853 (1974)
#                               I (DelS;R)=I(S;R)-I(!S;R)=
#                                          log [ f(S,R)/f(!S,R) ] + log [ f(!S)/f(S) ]
#				Bayes
#				                P(S) * P(R|S)
#				P(S|R) =  -------------------------
#				          SUM/j { P(Sj) * P(R|Sj) }
#				P(S|R) = probability for state S, given res R
#       in:                     $Lfano=  1|0:    compile fano info
#       in:                     $Lrobson=1|0:    compile robsons info diff
#       in:                     $Lbayes= 1|0:    compile bayes prob
#       in:                     $tmp{}:
#                               $tmp{"S"}=       "s1,s2,.."
#                               $tmp{"R"}=       "r1,r2,.."
#                               $tmp{"$R","$S"}= count of the number of residues $res in state $S
#       out:                    1|0,msg,  $res{}
#                               $res{"Rsum","$r"}=              sum for res $r
#                               $res{"Ssum","$s"}=              sum for state $s
#                               $res{"sum"}=                    total sum
#                               $res{"fano","$r","$s"}=         Fano information
#                               $res{"robson","$r","$s"}=       Robson information difference
#                               $res{"bayes","$r","$s"}=        Bayes prob (S|R, i.e. given R->S)
#                               $res{"bayes","Rsum","$r"}=      Bayes sum over all states for res $r
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."funcInfoConditional";$fhinLoc="FHIN_"."funcInfoConditional";
				# ------------------------------
				# get states/features
    return(&errSbr("tmp{R} not defined")) if (! defined $tmpLoc{"R"});
    return(&errSbr("tmp{S} not defined")) if (! defined $tmpLoc{"S"});
    $tmpLoc{"R"}=~s/^,*|,*$//g;
    $tmpLoc{"S"}=~s/^,*|,*$//g;
    @resLoc=split(/,/,$tmpLoc{"R"});
    @secLoc=split(/,/,$tmpLoc{"S"});
    undef %tmp2;
				# ------------------------------
    $sum=0;			# compile sums
    foreach $r (@resLoc) {	# features
	$tmp2{"Rsum","$r"}=0; 
	foreach $s (@secLoc) { 
	    $tmp2{"Rsum","$r"}+=$tmpLoc{"$r","$s"}; }
	$sum+=$tmp2{"Rsum","$r"};}
    foreach $s (@secLoc) {	# states
	$tmp2{"Ssum","$s"}=0; 
	foreach $r (@resLoc) { 
	    $tmp2{"Ssum","$s"}+=$tmpLoc{"$r","$s"}; }}
    $tmp2{"sum"}=$sum;
	
				# --------------------------------------------------
				# info (fano)
				# --------------------------------------------------
    if ($Lfano){
	foreach $r (@resLoc) {
	    $nr=$tmp2{"Rsum","$r"};
	    foreach $s (@secLoc) { 
		$up=0;
		$up=$tmpLoc{"$r","$s"}/$nr                  if ($nr>0);
		$lo=$tmp2{"Ssum","$s"}/$sum;
		$info=0;
		if ($lo>0){$info=$up/$lo;
			   $info=log($info)                 if ($info!=0); } 

		$tmp2{"fano","$r","$s"}=$info;
	    } }
    }

				# --------------------------------------------------
				# info DIFF (robson)
				# I (DelS;R)=I(S;R)-I(!S;R)=
				#        log [ f(S,R)/f(!S,R) ] + log [ f(!S)/f(S) ]
				# --------------------------------------------------
    if ($Lrobson){
	foreach $r (@resLoc) {
	    foreach $s (@secLoc) { 
		$neg=0;
		foreach $s2 (@secLoc) { next if ($s2 eq $s);
					$neg+=$tmpLoc{"$r","$s2"}; }
		$one=0;
		$one=$tmpLoc{"$r","$s"}/$neg                if ($neg>0);
		$one=log($one)                              if ($one>0);
		
		$two=0;
		$two=($sum-$tmp2{"Ssum","$s"})
		    /$tmp2{"Ssum","$s"}                     if ($tmp2{"Ssum","$s"}>0);
		$two=log($two)                              if ($two>0);
	    
		$tmp2{"robson","$r","$s"}=$one+$two; 
	    }} 
    }
				# --------------------------------------------------
				# Bayes
				#                    P(S) * P(R|S)
				# P(S|R) =  -------------------------
				#           SUM/j { P(Sj) * P(R|Sj) }
				#           
				# P(S|R) = probability for state S, given res R
				# --------------------------------------------------
    if ($Lbayes){
				# (1) get P(S) = SUM/j { P(Rj) * P(S|Rj) }
	foreach $s (@secLoc) { 
	    $tmp2{"bayes","pS","$s"}=0;
	    $tmp2{"bayes","pS","$s"}=($tmp2{"Ssum","$s"}/$sum)   if ($sum > 0);
	}
				# (2) get P(R|S)
	foreach $r (@resLoc) {
	    foreach $s (@secLoc) { 
		$tmp2{"bayes","RS","$r","$s"}=0;
		$tmp2{"bayes","RS","$r","$s"}=
		    ($tmpLoc{"$r","$s"}/$tmp2{"Ssum","$s"}) if ($tmp2{"Ssum","$s"} > 0); 
	    } }

				# (3) get P(S|R) = Bayes
	foreach $s (@secLoc) { 
	    foreach $r (@resLoc) {
		$tmp=0;
		foreach $s2 (@secLoc) { 
		    $tmp+= ( $tmp2{"bayes","pS","$s2"} * $tmp2{"bayes","RS","$r","$s2"} ); }
		$tmp2{"bayes","$r","$s"}=0;
		$tmp2{"bayes","$r","$s"}=
		    ($tmp2{"bayes","pS","$s"}*$tmp2{"bayes","RS","$r","$s"}) / $tmp 
			if ($tmp > 0);
	    } }
	foreach $r (@resLoc) {	# (4) get sum P(S|R) over S
	    $tmp=0;
	    foreach $s (@secLoc) { 
		$tmp+=$tmp2{"bayes","$r","$s"}; }
	    $tmp2{"bayes","Rsum","$r"}=$tmp; }
    }
				# ------------------------------
    undef %tmpLoc;		# slim-is-in!

    return(1,"ok $sbrName",%tmp2);
}				# end of funcInfoConditional

#===============================================================================
sub hsspGetFile { 
    local ($fileInLoc,$Lscreen,@dir) = @_ ; 
    local ($fileHssp,$dir,$tmp,$chainLoc,@dir2,$idLoc);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetFile                 searches all directories for existing HSSP file
#       in:                     $file,$Lscreen,@dir
#                               kwd  = noSearch -> no DB search
#       out:                    returned file,chain ($hssp,$chain), (if chain in file)
#       watch:                  loop onto itself:
#                               1prcH.hssp not found -> try 1prc.hssp
#--------------------------------------------------------------------------------
    $#dir2=$Lok=0;
    return(0,"no input file")   if (! defined $fileInLoc);
    $chainLoc="";$idLoc=$fileInLoc;$idLoc=~s/^.*\///g;
    $#dir=0                     if (! defined @dir);
    $Lscreen=0                  if (! defined $Lscreen);
    if (-d $Lscreen) { 
	@dir=($Lscreen,@dir);
	$Lscreen=0;}
    $fileInLoc=~s/\s|\n//g;
				# ------------------------------
				# is HSSP ok
    return($fileInLoc," ")      if (-e $fileInLoc && &is_hssp($fileInLoc));

				# ------------------------------
				# purge chain?
    if ($fileInLoc=~/^(.*\.hssp)_?([A-Za-z0-9])$/){
	$file=$1; $chainLoc=$2;
	return($file,$chainLoc) if (-e $file && &is_hssp($file)); }

				# ------------------------------
				# try adding directories
    foreach $dir(@dir){		# avoid endless loop when calling itself
	$Lok=1                  if ($dir =~ /\/data\/hssp/);
	push(@dir2,$dir);}
    @dir=@dir2;  push(@dir,"/data/hssp/") if (!$Lok); # give default

				# ------------------------------
				# before trying: purge chain
    $file=$fileInLoc; $chainLoc=" ";
    $file=~s/^(.*\.hssp)_?([A-Za-z0-9])$/$1/; 
    $chainLoc=$2 if (defined $2);
				# loop over all directories
    $fileHssp=
	&hsspGetFileLoop($file,$Lscreen,@dir);
    return($fileHssp,$chainLoc) if (-e $fileHssp && &is_hssp($fileHssp));

				# ------------------------------
                                # still not: dissect into 'id'.'chain'
    $tmp_file=$fileInLoc; $tmp_file=~s/^([A-Za-z0-9]+).*(\.hssp.*)$/$1$2/g;
    $fileHssp=
        &hsspGetFileLoop($tmp_file,$Lscreen,@dir);
    return($fileHssp,$chainLoc)    if (-e $fileHssp && &is_hssp($fileHssp));

				# ------------------------------
				# change version of file (1sha->2sha)
    $tmp1=substr($idLoc,2,3);
    foreach $it (1..9) {
        $tmp_file="$it"."$tmp1".".hssp";
        $fileHssp=
            &hsspGetFileLoop($tmp_file,$Lscreen,@dir);
	last if ($fileHssp ne "0");}
    return (0)                  if ( ! -e $fileHssp || &is_hssp_empty($fileHssp));
    return($fileHssp,$chainLoc);
}				# end of hsspGetFile

#===============================================================================
sub hsspGetFileLoop { 
    local ($fileInLoop,$Lscreen,@dir) = @_ ; 
    local ($fileOutLoop,$dir,$tmp);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   hsspGetFileLoop             loops over all directories
#       in:                     $file,$Lscreen,@dir
#       out:                    returned file
#--------------------------------------------------------------------------------
				# already ok 
    return($fileInLoop)         if (&is_hssp($fileInLoop));
				# missing extension
    $fileInLoop.=".hssp"        if ($fileInLoop !~ /\.hssp/);
				# already ok 
    return($fileInLoop)         if (&is_hssp($fileInLoop));
				# do NOT continue if starting with dir!!
    return(0)                   if ($fileInLoop =~ /^\//);

				# ------------------------------
    foreach $dir (@dir) {	# search through dirs
	$tmp=&complete_dir($dir) . $fileInLoop; # try directory
	$tmp=~s/\/\//\//g;	# '//' -> '/'
	print "--- hsspGetFileLoop: \t trying '$tmp'\n" if ($Lscreen);
	return($tmp)            if (-e $tmp && &is_hssp($tmp) );
    }
    return(0);			# none found
}				# end of hsspGetFileLoop

#===============================================================================
sub is_hssp {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$tmp);
#--------------------------------------------------------------------------------
#   is_hssp                     checks whether or not file is in HSSP format
#       in:                     $file
#       out:                    1 if is hssp; 0 else
#--------------------------------------------------------------------------------
				# highest priority: has to exist
    return (0)                  if (! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    open($fh, $fileInLoc) || 
	do { print "*** ERROR is_hssp $fileInLoc not opened to $fh\n";
	     return (0) ;};	# missing file -> 0
    $tmp=<$fh>;			# first line
    close($fh);
				# is HSSP
    return(1)                   if (defined $tmp && $tmp=~/^HSSP/);
    return(0);
}				# end of is_hssp

#===============================================================================
sub is_hssp_empty {
    local ($fileInLoc) = @_ ;local ($fh,$Lis);
#--------------------------------------------------------------------------------
#   is_hssp_empty               checks whether or not HSSP file has NALIGN=0
#       in:                     $file
#       out:                    1 if is empty; 0 else
#--------------------------------------------------------------------------------
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP";
    &open_file("$fh", "$fileInLoc") || return(0);
    while ( <$fh> ) {
	if ($_=~/^NALIGN\s+(\d+)/){
	    if ($1 eq "0"){
		close($fh); return(1);}
	    last; }}close($fh); 
    return 0;
}				# end of is_hssp_empty

#===============================================================================
sub is_hssp_list {
    local ($fileInLoc) = @_ ;local ($fh,$Lis,$fileRd,$fileLoc,$chainLoc,$LscreenLoc);
#--------------------------------------------------------------------------------
#   is_hssp_list                checks whether or not file contains a list of HSSP files
#       in:                     $file
#       out:                    returns 1 if is HSSP list, 0 else
#--------------------------------------------------------------------------------
    $LscreenLoc=0;
    return (0)                  if (! defined $fileInLoc || ! -e $fileInLoc);
    $fh="FHIN_CHECK_HSSP_LIST";
    &open_file("$fh", "$fileInLoc") || return(0);
    $Lis=0;
    while ( <$fh> ) {$fileRd=$_;$fileRd=~s/\s|\n//g;
		     next if (length($fileRd)<5);
		     ($fileLoc,$chainLoc)= 
			 &hsspGetFile($fileRd,$LscreenLoc);
		     $Lis=1 if (&is_hssp($fileLoc));
		     last; } close($fh);
    return $Lis;
}				# end of is_hssp_list

#==============================================================================
sub myprt_npoints {
    local ($npoints,$num_in) = @_; 
    local ($num,$beg,$ctprev,$ct,$numprev, $tmp,$tmp1,$tmp2, $out, $ct, $i);
    $[=1;
#-------------------------------------------------------------------------------
#   myprt_npoints               writes line with N dots of the form '....,....1....,....2' 
#       in:                     $number_of_points_per_line,$number_to_end_with
#       out:                    $line
#------------------------------------------------------------------------------
    $npoints=10*(1+int($npoints/10))
	if ( int($npoints/10)!=($npoints/10) );

    $ct=int(($num_in-1)/$npoints);
    $beg=$ct*$npoints; $num=$beg;
    for ($i=1;$i<=($npoints/10);++$i) {
	$numprev=$num; $num=$beg+($i*10);
	$ctprev=$numprev/10;
	if    ( $i==1 )                        {
	    $tmp=substr($num,1,1); $out="....,....".$tmp; }
	elsif ( $ctprev<10 )                   {
	    $tmp=substr($num,1,1); $out.="....,....".$tmp; }
	elsif ($i==($npoints/10) && $ctprev>=9){
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr(($num/10),1); }
	else                                   {
	    $tmp1=substr($ctprev,2);$tmp2="." x (4-length($tmp1));
	    $out.=$tmp1.$tmp2.",....".substr($num,1,1); }}
    $myprt_npoints=$out;
    return ($out);
}				# end of myprt_npoints

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
sub stat2DarrayWrt {
    local($sepL,$Lnum,$Lperc,$Lcperc,$Lfano,$Lrobson,$Lbayes,%tmp) = @_ ;
    local($sbrName,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   stat2DarrayWrt               writes counts
#       in:                     $sep        :    symbol for separating columns
#       in:                     $Lnum=   1|0:    write simple counts
#       in:                     $Lperc=  1|0:    write percentages (of total sum)
#       in:                     $Lcperc= 1|0:    write row percentages (of sum over rows)
#       in:                     $Lfano=  1|0:    write fano info
#       in:                     $Lrobson=1|0:    write robsons info diff
#       in:                     $Lbayes= 1|0:    write bayes prob
#       in:                     $tmp{}:
#                               $tmp{"S"}=       "s1,s2,.."
#                               $tmp{"R"}=       "r1,r2,.."
#                               $tmp{"$R","$S"}= number of residues $res in state $S
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $sbrName="lib-br:"."stat2DarrayWrt";$fhinLoc="FHIN_"."stat2DarrayWrt";

				# ------------------------------
				# get states/features
    return(&errSbr("tmp{R} not defined")) if (! defined $tmp{"R"});
    return(&errSbr("tmp{S} not defined")) if (! defined $tmp{"S"});
    $tmp{"R"}=~s/^,*|,*$//g;
    $tmp{"S"}=~s/^,*|,*$//g;
    @rloc=split(/,/,$tmp{"R"});
    @sloc=split(/,/,$tmp{"S"});
    undef %tmp2;
				# ------------------------------
				# get info
    ($Lok,$msg,%tmp2)=
	&funcInfoConditional($Lfano,$Lrobson,$Lbayes,%tmp);
    return(&errSbrMsg("stat2DarrayWrt: failed on info",$msg)) if (! $Lok);

				# --------------------------------------------------
				# build up to write
				# --------------------------------------------------
    $tmpWrt="";
				# ------------------------------
				# numbers
    $des="num";			# ------------------------------
    if ($Lnum){
	$f0="%-6s";
	$f2="%8d";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               sprintf("$sepL$f1",   "sum");
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    foreach $sloc (@sloc) {
		$tmpWrt.=       sprintf("$sepL$f2",   $tmp{"$rloc","$sloc"}); }
	    $tmpWrt.=           sprintf("$sepL$f2",   $tmp2{"Rsum","$rloc"});
	    $tmpWrt.=           "\n"; }
				# sum
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"sum");
	foreach $sloc (@sloc) {
	    $tmpWrt.=           sprintf("$sepL$f2",   $tmp2{"Ssum","$sloc"}); }
	$tmpWrt.=               sprintf("$sepL$f2",   $tmp2{"sum"});
	$tmpWrt.=               "\n"; 
    }
				# ------------------------------
				# percentages (over total counts)
    $des="perc";		# ------------------------------
    if ($Lperc){
	$f0="%-6s";
	$f2="%5.1f";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               sprintf("$sepL$f1",   "sum");
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    foreach $sloc (@sloc) {
		$tmpWrt.=       sprintf("$sepL$f2",   100*($tmp{"$rloc","$sloc"}/$tmp2{"sum"}));}
	    $tmpWrt.=           sprintf("$sepL$f2",   100*($tmp2{"Rsum","$rloc"}/$tmp2{"sum"}));
	    $tmpWrt.=           "\n"; }
				# sum
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"sum");
	foreach $sloc (@sloc) {
	    $tmpWrt.=           sprintf("$sepL$f2" ,  100*($tmp2{"Ssum","$sloc"}/$tmp2{"sum"}));}
	$tmpWrt.=               sprintf("$sepL$f2",   100);
	$tmpWrt.=               "\n";
    }
				# ------------------------------
				# c-percentages (row counts)
    $des="cperc";		# ------------------------------
    if ($Lcperc){
	$f0="%-6s";
	$f2="%5.1f";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               sprintf("$sepL$f1",   "sum");
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    $tmp=0;
	    foreach $sloc (@sloc) {
		$cperc=0;$cperc=100*($tmp{"$rloc","$sloc"}/$tmp2{"Rsum","$rloc"})
		    if ($tmp2{"Rsum","$rloc"}>0);
		$tmp+=$cperc;
		$tmpWrt.=       sprintf("$sepL$f2",   $cperc); }
	    $tmpWrt.=           sprintf("$sepL$f2",   $tmp);
	    $tmpWrt.=           "\n"; }
    }
				# ------------------------------
				# Fano information
    $des="fano";		# ------------------------------
    if ($Lfano){
	$f0="%-6s";
	$f2="%6.2f";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    foreach $sloc (@sloc) {
		$tmpWrt.=       sprintf("$sepL$f2",   $tmp2{"fano","$rloc","$sloc"}); }
	    $tmpWrt.=           "\n"; }
    }
				# ------------------------------
				# Robson information
    $des="robson";		# ------------------------------
    if ($Lrobson){
	$f0="%-6s";
	$f2="%6.2f";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    foreach $sloc (@sloc) {
		$tmpWrt.=       sprintf("$sepL$f2",   $tmp2{"robson","$rloc","$sloc"}); }
	    $tmpWrt.=           "\n"; }
    }
				# ------------------------------
				# Bayes prob
    $des="bayes";		# ------------------------------
    if ($Lbayes){
	$f0="%-6s";$f2="%5.1f";$f1=$f2;$f1=~s/(\d+)\.?\d*[df]/$1/;$f1.="s";$d1=$f1;$d1=~s/\D//g;
				# header
	$tmpWrt.=               sprintf("$f0$sepL$f1",$des,"aa");
	foreach $sloc (@sloc){
	    $tmpWrt.=           sprintf("$sepL$f1",   $sloc); }
	$tmpWrt.=               sprintf("$sepL$f1",   "sum");
	$tmpWrt.=               "\n";
				# data
	foreach $rloc (@rloc) {
	    $tmpWrt.=           sprintf("$f0$sepL$f1",$des,"$rloc");
	    foreach $sloc (@sloc) {
		$tmpWrt.=       sprintf("$sepL$f2",   100*$tmp2{"bayes","$rloc","$sloc"}); }
	    $tmpWrt.=           sprintf("$sepL$f2",   100*$tmp2{"bayes","Rsum","$rloc"});
	    $tmpWrt.=           "\n"; }
    }
				# ------------------------------
    undef %tmp; undef %tmp2;	# slim-is-in!
    return(1,"ok $sbrName",$tmpWrt);
}				# end of stat2DarrayWrt

