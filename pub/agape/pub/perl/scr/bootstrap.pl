#!/usr/bin/perl -w
##!/usr/sbin/perl -w
#
$scrName=$0;$scrName=~s/^.*\/|\.pl//g;
$scrGoal="does boot-strap experiment\n".
    "     \t in:  RDB file\n".
    "     \t out: sigma\n".
    "     \t \n".
    "     \t \n".
    "     \t ";
#  
# 
#------------------------------------------------------------------------------#
#	Copyright				        	2001	       #
#	Burkhard Rost		rost@columbia.edu			       #
#	CUBIC (Columbia Univ)	http://cubic.bioc.columbia.edu/   	       #
#       Dept Biochemistry & Molecular Biophysics			       #
#       630 West, 168 Street						       #
#	New York, NY 10032	http://www.columbia.edu/~rost/                 #
#				version 0.1   	Sep,    	2001	       #
#------------------------------------------------------------------------------#
#

$[ =1 ;				# count from one

				# ------------------------------
				# defaults
%par=(
      '', "",			# 
      );
				# number of sample points to pick for each experiment
				#    if fraction: take that fraction of all points
$par{"npick"}=                  0.2;
				# number of repetitions for experiment
$par{"nrepeat"}=                100;

$sep=     "\t";
$col2read="all";

@kwd=sort (keys %par);
$Ldebug=0;
$Lverb= 0;

				# ------------------------------
if ($#ARGV<1 ||			# help
	$ARGV[1] =~/^(-h|help|special)/){
    print  "goal: $scrGoal\n";
    print  "use:  '$scrName file.rdb'\n";
    print  "opt:  \n";
				#      'keyword'   'value'    'description'
    printf "%5s %-15s=%-20s %-s\n","","fileOut",  "x",        "name of output file";

    printf "%5s %-15s %-20s %-s\n","","npick",    "int/real", "number of sample points to pick for each experiment";
    printf "%5s %-15s %-20s %-s\n","","",         "",         "if fraction: take that fraction of all points";
    printf "%5s %-15s %-20s %-s\n","","nrepeat",  "int",      "number of repetitions for experiment (default: $nrepeat)";

    printf "%5s %-15s=%-20s %-s\n","","col",      "1,5",      "columns to read, either numerical=number of column";
    printf "%5s %-15s %-20s %-s\n","","",         "num",      "OR:   names of columns";
    printf "%5s %-15s %-20s %-s\n","","",         "",         "'all' to do all columns";
    printf "%5s %-15s %-20s %-s\n","","",         "",         "NOTE: to process many, give them as comma separated list";
    printf "%5s %-15s %-20s %-s\n","","",         "",         "DEFAULT: $col2read";

    printf "%5s %-15s=%-20s %-s\n","","sep",      "x",        "separator between columns (words 'TAB' 'SPACE' 'COMMA' are recognised! default: tabs";

    printf "%5s %-15s %-20s %-s\n","","det",      "no value", "write detailed distribution (only for ONE nrepeat and ONE col!)";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",        "",         "continued";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";

    printf "%5s %-15s %-20s %-s\n","","dbg",   "no value",   "debug mode";
    printf "%5s %-15s %-20s %-s\n","","silent|-s","no value","no screen output";
    printf "%5s %-15s %-20s %-s\n","","verb|-s",  "no value","verbose";
#    printf "%5s %-15s %-20s %-s\n","","noScreen", "no value","";
#    printf "%5s %-15s=%-20s %-s\n","","",   "x", "";
#    printf "%5s %-15s %-20s %-s\n","","",   "no value","";
				# special
    if (($#ARGV==1 && $ARGV[1]=~/^special/) ||
	($#ARGV>1 && $ARGV[1] =~/^(-h|help)/ && $ARGV[2]=~/^spe/)){
    }

    if (defined %par && $#kwd > 0){
	$tmp= sprintf("%5s %-15s  %-20s %-s\n","","-" x 15 ,"-" x 20,"-" x 30);
	$tmp.=sprintf("%5s %-15s  %-20s %-s\n","","other:","default settings: "," ");
	$tmp2="";
	foreach $kwd (@kwd){
	    next if (! defined $par{$kwd});
	    next if ($kwd=~/^\s*$/);
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
#$fhin="FHIN";
$fhout="FHOUT";
$#fileIn=0;
$Ldet=0;
				# ------------------------------
				# read command line
foreach $arg (@ARGV){
#    next if ($arg eq $ARGV[1]);
    if    ($arg=~/^fileOut=(.*)$/i)       { $fileOut=        $1;}
    elsif ($arg=~/^de?bu?g$/)             { $Ldebug=         1;
					    $Lverb=          1;}
    elsif ($arg=~/^verb(ose)?$|^\-v$/)    { $Lverb=          1;}
    elsif ($arg=~/^silent$|^\-s$/)        { $Lverb=          0;}

    elsif ($arg=~/^det$/)                 { $Ldet=           1;}

    elsif ($arg=~/^nrepeat=(.*)$/)        { $nrepeat=        $1;}
    elsif ($arg=~/^npick=(.*)$/)          { $npick=          $1;}

    elsif ($arg=~/^col=(.*)$/)            { $col2read=       $1;}
    elsif ($arg=~/^sep=(.*)$/)            { $sep=            $1;
					    if    ($sep =~ /TAB/i){
						$sep=            "\t";}
					    elsif ($sep =~ /SPACE/i){
						$sep=            "\s";}
					    elsif ($sep =~ /COMMA/i){
						$sep=            ",";}}
#    elsif ($arg=~/^=(.*)$/){ $=$1;}
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
if (! defined $fileOut){
    $tmp=$fileIn;
    $tmp=~s/^.*\///g;
    $tmp=~s/\..*$//g;
    $fileOut=   "Outboot-".$tmp.".tmp";
    $fileOutDet="Outbootdet-".$tmp.".tmp";
}
elsif ($Ldet){
    $fileOutDet=$fileOut."_det";
}
    

undef %res;
@npick=  split(/,/,$npick);
@nrepeat=split(/,/,$nrepeat);


				# --------------------------------------------------
				# the whole bloddy stuff
				# --------------------------------------------------
$ctfile=0;
foreach $fileIn (@fileIn){
    ++$ctfile;
    if (! -e $fileIn){print "-*- WARN $scrName: no fileIn=$fileIn\n";
		      next;}
    print "--- $scrName: working on fileIn=$fileIn!\n";
#    printf "--- $scrName: working on %-25s %4d (%4.1f perc of job)\n",$fileIn,$ctfile,(100*$ctfile/$#fileIn);
				# ------------------------------
				# (1) read file(s)
				#     out GLOBAL %rdb{NROWS|$ct,name}
				#     out @col=names read
				# ------------------------------
    ($Lok,$msg,$colall,$colnumber)=
	&rdData($fileIn);	&errScrMsg("failed to read $fileIn",$msg,$scrName) if (! $Lok);
    @col=   split(/\t/,$colnumber);
    @colall=split(/\t/,$colall);

				# ------------------------------
				# random numbers
    srand(time|$$);             # seed random
#    srand(100010);		# seed random

				# ------------------------------
				# (2) now random picks
				# ------------------------------

    foreach $col (@col){
	$#data2do=0;
	foreach $it (1..$rdb{"NROWS"}){
	    push(@data2do,$rdb{$it,$col});
	}
	foreach $nrepeat2 (@nrepeat) {
	    foreach $npick2 (@npick){
				# is fraction!
		$npick2=int($rdb{"NROWS"}*$npick2) if ($npick2<1);

		($Lok,$msg,$ave,$var,$data)=
		    &averageCommon
			($rdb{"NROWS"},$npick2,$nrepeat2,@data2do);
		&errScrMsg("failed on averageCommon col=$col, nrepeat=$nrepeat2, npick=$npick2",$msg) 
		    if (! $Lok);
		$res{$ctfile,$col,$nrepeat2,$npick2,"ave"}=$ave;
		$res{$ctfile,$col,$nrepeat2,$npick2,"var"}=$var;

		
		$res{$ctfile,$col,$nrepeat2,$npick2,"det"}=$data
		    if ($Ldet);
#		print "xx col=$col, nrepeat=$nrepeat2, npick=$npick2, ave=$ave var=$var\n"
#		    if ($Ldebug);
	    }
	}
	$res{$ctfile,"col"}=join(',',@col);
    }
}

				# --------------------------------------------------
				# output file (general stat)
				# --------------------------------------------------
open($fhout,">".$fileOut) || warn "*** $scrName ERROR creating fileOut=$fileOut";

				# ------------------------------
				# column names
$tmpwrt="col".$sep."nrepeat".$sep."npick".$sep."ave".$sep."err";
print $fhout
    $tmpwrt,"\n";
print $tmpwrt,"\n"              if ($Ldebug);

				# ------------------------------
				# data
foreach $ctfile ($#fileIn){
    @col=split(/,/,$res{$ctfile,"col"});
    foreach $col (@col){
	foreach $npick2 (@npick){
	    foreach $nrepeat2 (@nrepeat) {
				# is fraction!
		$npick2=int($rdb{"NROWS"}*$npick2) if ($npick2<1);

		$tmpwrt=
		    $col.$sep.
			$nrepeat2.$sep.
			    $npick2.$sep;
		$tmpwrt.=sprintf("%6.2f".$sep,$res{$ctfile,$col,$nrepeat2,$npick2,"ave"});
		$tmpwrt.=sprintf("%6.2f".$sep,$res{$ctfile,$col,$nrepeat2,$npick2,"var"});
		print $fhout
		    $tmpwrt,"\n";
		print $tmpwrt,"\n"              if ($Ldebug);
	    }
	}
    }
}
close($fhout);

				# --------------------------------------------------
				# output file (general stat)
				# --------------------------------------------------
if ($Ldet){
    open($fhout,">".$fileOutDet) || warn "*** $scrName ERROR creating fileOutDet=$fileOutDet";

				# restrict to one file
    $ctfile=1;
    @col=split(/,/,$res{$ctfile,"col"});
				# restrict to first column
    $col=$col[1];
				# restrict to one nrepeat
    $nrepeat2=$nrepeat[1];

    $tmpwrt= "# file   =".$fileIn[$ctfile]."\n";
    $tmpwrt.="# col    =".$col."\n";
    $tmpwrt.="# nrepeat=".$nrepeat2."\n";

				# ------------------------------
				# column names
    $tmpwrt="no";
    $#tmp=0;
    foreach $npick2 (@npick){
	$npick2=int($rdb{"NROWS"}*$npick2) if ($npick2<1);
	push(@tmp,$npick2);
    }
    @npick2=@tmp;

    foreach $npick2 (@npick2){
	$tmpwrt.=$sep.$npick2;
    }

    print $fhout
	$tmpwrt,"\n";
    print $tmpwrt,"\n"              if ($Ldebug);

				# ------------------------------
				# data
    @tmp=split(/\t/,$res{$ctfile,$col,$nrepeat2,$npick2[1],"det"});
    $nrow=$#tmp;
    
    foreach $itrow (1..$nrow){
	$tmpwrt=$itrow;
	foreach $npick2 (@npick2){
	    @tmp=split(/\t/,$res{$ctfile,$col,$nrepeat2,$npick2,"det"});
	    $tmpwrt.=$sep.sprintf("%5.2f",$tmp[$itrow]);
	}

	print $fhout
	    $tmpwrt,"\n";
	print $tmpwrt,"\n"              if ($Ldebug);
    }
    close($fhout);
}

print "--- output  in $fileOut\n"    if (-e $fileOut);
print "--- details in $fileOutDet\n" if ($Ldet && -e $fileOutDet);

exit;


#===============================================================================
sub averageCommon {
    local($nrowsLoc,$npickLoc,$nrepeatLoc,@dataLoc) = @_ ;
    local($SBR1,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   averageCommon                       
#       in:                     $nrowsLoc   number of data points
#       in:                     $npickLoc   number of subset of data points for one experiment
#       in:                     $nrepeatLoc number of bootstrap repeats
#       in:                     $Loc   number of data points
#                               
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR1=$tmp."averageCommon";
				# --------------------------------------------------
				# loop over number of boot-strap experiments
				# --------------------------------------------------
    $#ave=0;
    foreach (1..$nrepeatLoc){
				# ------------------------------
				# returns the ones to take
	($Lok,$msg,@take)=
	    &getRandomSet
		($nrowsLoc,
		 $npickLoc);	&errSbrMsg("failed on getRandomSet nrowsLoc=$nrowsLoc, pick=$npickLoc",
					   $msg,$SBR1) if (! $Lok);
	    
	if ($#take > $npickLoc){
	    print "*** problem too many to npick=",$npickLoc,", ntake=",$#take,"\n";
	    exit;}
	if ($#take < 1){
	    print "*** problem too few?? to npick=",$npickLoc,", ntake=",$#take,"\n";
	    exit;}
				# ------------------------------
				# average 
	$ave=0;
	foreach $it (@take){
	    $ave+=$dataLoc[$it];
	}
	$ave=$ave/$#take;
	push(@ave,$ave);
#	print "xx itrepeat=$itrepeat, nrow=$nrowsLoc, npick=$npickLoc, ave1=$ave\n"
#	    if ($Ldebug);
    }

    ($ave,$var)=
	&stat_avevar(@ave);
    $var=sqrt($var);
    return(1,"ok $SBR1",$ave,$var,join("\t",@ave));
}				# end of averageCommon


#===============================================================================
sub getRandomSet {
    local($numrowLoc,$numwantLoc) = @_ ;
    local($SBR2,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   getRandomSet                selects a random list of proteins (identical sets)
#       in:                     $numrow   number of data points
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR2=$tmp."getRandomSet";
    $fhinLoc="FHIN_"."getRandomSet";$fhoutLoc="FHOUT_"."getRandomSet";

    $#takenum=0;
    $ct=0;
    foreach $it (1..$numrowLoc){
	$takenum[$it]=0;
    }
				# ------------------------------
				# find proteins for one CASP
    while ($ct < $numwantLoc){
				# randomly select sample 
	$it=int(rand($numrowLoc))+1;

	if    ($it > $numrowLoc) {	# upper bound
	    $it=$numrowLoc;}
	elsif ($it < 1){	# lower bound (security)
	    $it=1;}
				# repeat if already takenumn
	while ($takenum[$it]){
				# randomly select sample again
	    $it=int(rand($numrowLoc))+1;
				# upper bound
	    if    ($it > $numrowLoc) {
		$it=$numrowLoc;}
	    elsif ($it < 1){	# lower bound (security)
		$it=1;}
	}
	$takenum[$it]=1;
	++$ct;
    }				# end of one bootstrap experiment
    $#take=0;
    foreach $it (1..$#takenum){
	next if (! $takenum[$it]);
	push(@take,$it);
    }
    $#takenum=0;
    return(1,"ok $SBR2",@take);
}				# end of getRandomSet

#==============================================================================
# library collected (begin) lll
#==============================================================================

#===============================================================================
sub align_a_la_blast {
    local($seq1Loc,$seq2Loc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   align_a_la_blast            finds longest common word between string 1 and 2
#       in:                     $string1
#       in:                     $string2
#       out:                    1|0,msg,$lali,$beg1,$beg2
#                               $lali      length of common substring
#                               $beg1      first matching residue in string1
#                               $beg2      first matching residue in string2
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."align_a_la_blast";
    $fhinLoc="FHIN_"."align_a_la_blast";$fhoutLoc="FHOUT_"."align_a_la_blast";
				# ------------------------------
				# check arguments
    return(&errSbr("not def seq1Loc!"))          if (! defined $seq1Loc);
    return(&errSbr("not def seq2Loc!"))          if (! defined $seq2Loc);
#    return(&errSbr("not def !"))          if (! defined $);

#    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc);

				# ------------------------------
				# local defaults
    $wordlenLoc=               10;
    $wordlenLoc=$par{"wordlen"} if (defined $par{"wordlen"});

				# ------------------------------
				# all upper
    $seq1Loc=~tr/[a-z]/[A-Z]/;
    $seq2Loc=~tr/[a-z]/[A-Z]/;

				# long enough
    $len1=length($seq1Loc);
    if ($len1 < $wordlenLoc){
	return(2,"sequence 1 too short (is $len1, should be > $wordlenLoc)");
    }
				# chop up sequence 1
    $#tmpbeg=$#tmpend=0;
    
    @seq1Loc=split(//,$seq1Loc);
    $it=0;
    while ($it <= ($len1-$wordlenLoc)){
	++$it;
	$word1=substr($seq1Loc,$it,$wordlenLoc);
				# DOES match: try to extend
	if ($seq2Loc=~/$word1/){
	    $it2=$it+$wordlenLoc-1;
	    while ($seq2Loc=~/$word1/ && 
		   ($it2 < $len1)){
		++$it2;
		$word1.=$seq1Loc[$it2];
	    }
				# last did not match anymore
	    chop($word1)        if ($seq2Loc!~/$word1/);
	    $beg=$it;
	    $end=$it+length($word1)-1;
	    $it=$end;
	    push(@tmpbeg,$beg);
	    push(@tmpend,$end);
	}
    }
				# ------------------------------
				# find longest
    $max=$pos=0;
    foreach $it (1..$#tmpbeg){
	$len=1+$tmpend[$it]-$tmpbeg[$it];
	if ($max < $len){
	    $max=$len;
	    $pos=$it;}
    }
				# ------------------------------
				# find out where it matches
    
    $word1=substr($seq1Loc,$tmpbeg[$pos],$max);
    $beg1=$tmpbeg[$pos];
    $#seq1Loc=$#tmpbeg=$#tmpend=0;

    $tmp=$seq2Loc;
    $pre="";
    if ($tmp=~/^(.*)$word1/){
	$tmp=~s/^(.*)($word1)/$2/;
	$pre=$1                 if (defined $1);}
    $beg2=1;
    $beg2=length($pre)+1       if (length($pre)>0);
    return(1,"ok $sbrName",$max,$beg1,$beg2);
}				# end of align_a_la_blast

#===============================================================================
sub bynumber { 
#-------------------------------------------------------------------------------
#   bynumber                    function sorting list by number
#-------------------------------------------------------------------------------
    $a<=>$b; 
}				# end of bynumber

#===============================================================================
sub bynumber_high2low { 
#-------------------------------------------------------------------------------
#   bynumber_high2low           function sorting list by number (start with high)
#-------------------------------------------------------------------------------
    $b<=>$a; 
}				# end of bynumber_high2low

#===============================================================================
sub convert_accRel2oneDigit {
    local ($accRelLoc) = @_;
    $[=1;
#----------------------------------------------------------------------
#   convert_accRel2oneDigit     project relative acc to numbers 0-9
#                               by: n = max ( 9 , int(sqrt (rel_exp)) )
#       in:                     $naliSatLoc   : number of alignments when no db taken
#       out:                    1|0,msg,$converted_acc
#       err:                    (1,'ok'), (0,'message')
#----------------------------------------------------------------------
				# check input
    return(0,"*** ERROR convert_accRel2oneDigit: relAcc=$accRelLoc???\n")
	if ( $accRelLoc < 0 );
				# SQRT
    $out= int ( sqrt ($accRelLoc) );
                                # saturation: limit to 9
    $out= 9  if ( $out >= 10 );
    return(1,"ok",$out);
}				# end of convert_accRel2oneDigit

#===============================================================================
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

#===============================================================================
sub dsspRdSeqSecAcc {
    local($fileInLoc,$chnInLoc,$kwdInLoc) = @_ ;
    local($sbrName,$fhinLoc,$fhoutLoc,$tmp,$Lok);
    $[ =1 ;
#-------------------------------------------------------------------------------
#   dsspRdSeqSecAcc             reads DSSP file
#                               NOTE: chain breaks are skipped!!
#                               
#       in:                     $fileInLoc:  DSSP file
#       in:                     $chnInLoc:   chain to read (' ' if all)
#       in:                     $kwdInLoc:   seq,sec,acc(nodssp,nopdb): directs what to read!
#       out:                    1|0,msg
#                               
#       out GLOBAL:             %tmp{"NROWS"}=number of residues
#       out GLOBAL:             $tmp{$ct,"chn|seq|sec|acc|nodssp|nopdb"} respective values
#       out GLOBAL:             $tmp{<header|compnd|source|author>}
#                               
#       err:                    (1,'ok'), (0,'message')
#-------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $sbrName=$tmp."dsspRdSeqSecAcc";
    $fhinLoc="FHIN_"."dsspRdSeqSecAcc";$fhoutLoc="FHOUT_"."dsspRdSeqSecAcc";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!"))     if (! defined $fileInLoc);
    return(&errSbr("not def chnInLoc!"))      if (! defined $chnInLoc);
    $kwdInLoc="seq,sec,acc"                   if (! defined $kwdInLoc);
				# ------------------------------
				# file existing?
    return(&errSbr("no fileIn=$fileInLoc!"))  if (! -e $fileInLoc && ! -l $fileInLoc);
				# ------------------------------
				# local settings
    $#kwdTmp=0;
    push(@kwdTmp,"seq")         if ($kwdInLoc=~/seq/);
    push(@kwdTmp,"sec")         if ($kwdInLoc=~/sec/);
    push(@kwdTmp,"acc")         if ($kwdInLoc=~/acc/);
    push(@kwdTmp,"nodssp")      if ($kwdInLoc=~/nodssp/);
    push(@kwdTmp,"nopdb")       if ($kwdInLoc=~/nopdb/);

				# ------------------------------
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));

    undef %tmp;
				# ------------------------------
				# read HEADER
    while (<$fhinLoc>) {
				# stop header
	last if ($_=~/^\s*\#\s*RESIDUE/);

	$line=$_; $line=~s/\n//g;

	if ($line=~/HEADER\s+(\S.+)$/){
	    $tmp{"header"}=$1;
				# remove '  16-JAN-81   1PPT '
	    $tmp{"header"}=~s/\s+\d\d....\-\d+\s+\d...\s*$//g;
	    next; }

	if ($line=~/COMPND\s+(\S.+)$/){
	    $tmp{"compnd"}=$1;
	    $tmp{"compnd"}=~s/^\s*|\s*$//g;
	    next; }
	if ($line=~/SOURCE\s+(\S.+)$/){
	    $tmp{"source"}=$1;
	    $tmp{"source"}=~s/^\s*|\s*$//g;
	    next; }
	if ($line=~/AUTHOR\s+(\S.+)$/){
	    $tmp{"author"}=$1;
	    $tmp{"author"}=~s/^\s*|\s*$//g;
	    next; }
	if ($line=~/^\s*(\d+)\s*(\d+).*TOTAL NUMBER OF RESIDUES/){
	    $tmp{"NROWS"}= $1;
	    $tmp{"nres"}=  $tmp{"NROWS"};
	    $tmp{"nchn"}=  $2;
	    next; }
    }

				# ------------------------------
				# read file body
    $ctres=0;
    while (<$fhinLoc>) {	# 
	$line=$_; $line=~s/\n//g;
				# all we need in first 40
	undef %tmp2;
	$line=          substr($line,1,40);
	$chn=           substr($line,12,1);

				# skip since chain not wanted?
	next if ($chnInLoc ne " " && 
		 $chn ne $chnInLoc);

	$tmp2{"seq"}=   substr($line,14,1);
				# skip chain breaks
	next if ($tmp2{"seq"} eq "!");

	$tmp2{"nodssp"}=substr($line,1,5); $tmp2{"nodssp"}=~s/\s//g;
	$tmp2{"nopdb"}= substr($line,6,5); $tmp2{"nopdb"}=~s/\s//g;

	$tmp2{"sec"}=   substr($line,17,1);$tmp2{"sec"}=~s/ /L/;
	$tmp2{"acc"}=   substr($line,36,3);$tmp2{"acc"}=~s/\s//g;
	++$ctres;
	foreach $kwd (@kwdTmp){
	    $tmp{$ctres,$kwd}=$tmp2{$kwd};
	}
	$tmp{$ctres,"chn"}=   $chn;
    }

				# correct number of residues
    $tmp{"nres"}=  
	$tmp{"NROWS"}=
	    $ctres;
				# clean up
    undef %tmp2;		# slim-is-in
    $#kwdTmp=0;			# slim-is-in
    
    return(1,"ok $sbrName");
}				# end of dsspRdSeqSecAcc

#===============================================================================
sub errSbr    {local($txtInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbr                      simply writes '*** ERROR $sbrName: $txtInLoc'
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc");
}				# end of errSbr

#===============================================================================
sub errSbrMsg {local($txtInLoc,$msgInLoc,$sbrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errSbrMsg                   simply writes '*** ERROR $sbrName: $txtInLoc\n'.$msg
#-------------------------------------------------------------------------------
	       $sbrNameLocy=$sbrName if (! defined $sbrNameLocy);
	       if (! defined $txtInLoc){
		   print "xx msgInLoc=$msgInLoc\n";
		   $msgInLoc=""      if (! defined $msgInLoc);
		   print "xx errSbrMsg: no txtin!\n";}
	       else {
		   $txtInLoc.="\n";
		   $txtInLoc=~s/\n\n+/\n/g;
		   $msgInLoc.="\n";
		   $msgInLoc=~s/\n\n+/\n/g;}
	       return(0,"*** ERROR $sbrNameLocy: $txtInLoc".$msgInLoc);
}				# end of errSbrMsg

#===============================================================================
sub errScrMsg {local($txtInLoc,$msgInLoc,$scrNameLocy) = @_ ;
#-------------------------------------------------------------------------------
#   errScrMsg                   writes message and EXIT!!
#-------------------------------------------------------------------------------
	       $scrNameLocy=$scrName if (! defined $scrNameLocy);
	       $txtInLoc.="\n";
	       $txtInLoc=~s/\n\n+/\n/g;
	       if (defined $msgInLoc) {
		   $msgInLoc.="\n";
		   $msgInLoc=~s/\n\n+/\n/g;}
	       else {
		   $msgInLoc="";}
	       print "*** ERROR $scrNameLocy: $txtInLoc".$msgInLoc;
	       exit; 
}				# end of errScrMsg

#===============================================================================
sub rdData {
    local ($fileInLoc) = @_ ;
    local($SBR6,$fhinLoc,$tmp,$Lok);
    $[ =1 ;
#--------------------------------------------------------------------------------
#   rdData                      reads content of data file
#       in:                     $fileInLoc
#       in GLOBAL:              $col2read
#                               
#       out GLOBAL:             rdb{"NROWS"}   returns the numbers of rows read
#                               rdb{$ct,"kwd"} results for row ct and kwd
#       out:                    1|0,msg,  implicit:
#       err:                    (1,'ok'), (0,'message')
#--------------------------------------------------------------------------------
    $tmp=$0;$tmp=~s/^.*\/|\.pl//g;$tmp.=":";
    $SBR6=$tmp."rdData";
    $fhinLoc="FHIN_"."rdData";
				# ------------------------------
				# check arguments
    return(&errSbr("not def fileInLoc!",   $SBR6)) if (! defined $fileInLoc);
    return(&errSbr("no fileIn=$fileInLoc!",$SBR6)) if (! -e $fileInLoc && ! -l $fileInLoc);
				# open file
    open($fhinLoc,$fileInLoc) || return(&errSbr("fileInLoc=$fileInLoc, not opened"));
    undef %rdb;
				# ------------------------------
				# HEADER.rdb
    $ctline=0;
    while (<$fhinLoc>) {
	++$ctline;
	$_=~s/\n//g;
	next if ($_=~/^\#/);	# skip comments
	$_=~s/[\s\t]*$//g;
				# first line=names
	@name=split(/$sep+/,$_); 
	last;
    }
				# ------------------------------
				# which ones to read?
    $#name2read=0;
    if    ($col2read=~/all/){	# read all columns
	foreach $name (@name){
	    $rdb{$name}=1;
	    push(@name2read,$name);
	}}
    elsif ($col2read=~/^[\d,]+$/){ # read certain column numbers
	@tmp=split(/,/,$col2read);
	undef %tmp;
	foreach $tmp (@tmp){
	    $tmp{$tmp}=1;
	}
	foreach $it (1..$#name){
	    next if (! defined $tmp{$it});
	    $rdb{$name[$it]}=1;
	    push(@name2read,$name[$it]);
	}}
    elsif ($col2read=~/^[\d,]+$/){ # read certain column names
	@name2read=split(/,/,$col2read);
	undef %tmp;
	foreach $tmp (@name){
	    $tmp{$tmp}=1;
	}
	foreach $name (@name2read){
	    if (! defined $tmp{$name}){
		$err=  "*** file=$fileInLoc names ARE: ".join(',',@name,"\n");
		$err.= "*** however you wanted to read column name=$name, why??\n";
		return(&errSbrMsg("problem with col2read",$err,$SBR6));}
	    $rdb{$name}=1;
	}}
    else{
	$err=  "*** file=$fileInLoc: somehow col2read=$col2read is wrong!!\n";
	$err.= "***      either of the following\n";
	$err.= "***      'all'\n";
	$err.= "***      '".join("|",(1..$#name),join(',',(1..$#name)))."'\n";
	$err.= "***      '".join("|",@name,join(',',@name))."'\n";
	return(&errSbrMsg("problem with col2read",$err,$SBR6));
    }
    undef %tmp;
    foreach $tmp (@name2read){
	$tmp{$tmp}=1;
    }
    $#it2read=0;
    foreach $it (1..$#name){
	next if (! defined $tmp{$name[$it]});
	push(@it2read,$it);
    }

				# ------------------------------
				# BODY.rdb
    $ctsam=0;
    $#nonumber=0;
    foreach $it (@it2read){
	$nonumber[$it]=0;
    }
	
    while (<$fhinLoc>) {
	++$ctline;
	$_=~s/\n//g;
	next if ($_=~/^\#/);	# skip comments
	$_=~s/[\s\t]*$//g;
	++$ctsam;
	@tmp=split(/$sep+/,$_); 
	foreach $it (@it2read){
	    if (! defined $tmp[$it]){
		$rdb{$ctsam,$name[$it]}="";
		$nonumber[$it]=1; 
		next; }
	    $rdb{$ctsam,$name[$it]}=$tmp[$it];
				# if not a number, the column disqualifies!
	    if ($tmp[$it]!~/^[\d\.\-]+$/){
		$nonumber[$it]=1; }
	}
    }
    close($fhinLoc);

    $#namenumber=0;
    foreach $it (@it2read){
	next if ($nonumber[$it]);
	push(@namenumber,$name[$it]);
    }

    $rdb{"NROWS"}=$ctsam;
    return(1,"ok $SBR6",join("\t",@name2read),join("\t",@namenumber));
}				# end of rdData

#===============================================================================
sub stat_avevar {
    local(@dataLoc)=@_;
    local($i, $ave, $var);
    $[=1;
#----------------------------------------------------------------------
#   stat_avevar                 computes average and variance
#       in:                     @dataLoc (vector)
#       out:                    $AVE, $VAR
#          GLOBAL:              $AVE, $VAR (returned as list)
#----------------------------------------------------------------------
    $ave=$var=0;
				# no dataLoc
    return(0,0)                 if ($#dataLoc < 1);
				# compile sum
    foreach $i (@dataLoc) { 
	$ave+=$i; } 
				# get average
    $AVE=$VAR=0;
    $AVE=($ave/$#dataLoc);
				# get variance
    foreach $i (@dataLoc) { 
	$tmp=($i-$AVE); 
	$var+=($tmp*$tmp); } 
    $VAR=($var/($#dataLoc-1))      if ($#dataLoc > 1);
    $#dataLoc=0;
    return ($AVE,$VAR);
}				# end of stat_avevar

