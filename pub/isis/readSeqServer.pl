#!/usr/bin/perl
##!/usr/local/bin/perl
$Fil="";
$lsl="yes";

if (!defined $ENV{'ISIS'}){
    $ENV{"ISIS"} = $ENV{'PP_ROOT'}."/pub/isis";	  
}

$dirIsis = $ENV{"ISIS"};

if (@ARGV<3){die "Usage: $0 file_name.hssp [file_name.rdbProf|file_name.dssp] output.file\n"}
@e=@ARGV;
$g=8;#$e[0];#diff between output nodes
$sch=5;#$e[1];#half stretch
$cr=7;#$e[2];#crowd
$crgs=1;#crowd of gs
$topgap=101;#maximal difference between outputnodes
$sfile=$e[1];
$nitr=51;#$e[4];
$war="";
#############################################################
@a=split (/\//,$sfile);
$sfile=pop @a;
($sfile,$ft)=split (/\./,$sfile);
if ($ft eq "dssp"){$struc="y"}
#elsif ($ft eq "rdbProf"){$struc="y"}
elsif ($ft eq "profRdb"){$struc="n"}
else{die "second file must be file_name.rdbProf OR file_name.dssp\n"}
open (I1,">$dirIsis/tin_forTest$sfile") || 
    die "-*- Could not open $dirIsis/tin_forTest$sfile\n-*- System Err:$!\n" ;
open (O1,">$dirIsis/tout_forTest$sfile") ||
        die "-*- Could not open $dirIsis/tout_forTest$sfile\n-*- System Err:$!\n" ;
open (MAP,">$dirIsis/map_forTest$sfile") ||
    die "-*- Could not open $dirIsis/map_forTest$sfile\n-*- System Err:$!\n" ;
open (OUT,">$e[2]") ||
    die "-*- Could not open $dirIsis/$sfile.pred\n-*- System Err:$!\n" ;	

$empty="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ";

print OUT ": strech=$sch crowd_predictions=$cr gap=$g itr=$nitr\n";
############## LOOK FOR PDB FILE ############################

#if ($sfile ne "none"){
#  $struct="y";
#  ($b,$read)=split (/\|pdb\|/,$read);
#  $pdb=$read;
#  print "pdb=$pdb\n";
#  print OUT "using $pdb\n";
#  if ($pdb=~/_/){$chain=chop $pdb;chop $pdb}
#  print "chain=$chain\n";

#  if ($chain ne " "){$tout=$pdb."_".$chain;}
#  else{$tout=$pdb}
#  if ($struct eq "y"){
#    open (PDB,">$tout.pdb");
#    $swc=0;$prevc="";
#    foreach $p (`cat /data/pdb/$pdb.pdb`){
#      if (($p=~/^HEADER/) or ($p=~/^TITLE/)or ($p=~/^COMPND/)){print PDB $p}
#      if ($p=~/^ATOM/){
#	$c=substr($p,21,1);
#	if (($c ne $prevc) and ($prevc eq $chain)){$swc++;print "swc=$swc $p"}
#	if ($swc==2){print PDB "TER\nEND";print "$p getting out\n";last}
#	$prevc=$c;
#	if ($c eq $chain){print PDB $p}
#      }
#      if (($p=~/^TER/) and ($prevc eq $chain)){print PDB $p;last}
#    }
#}
#  if ($chain ne " "){$out="$pdb"."_"."$chain"}
#  else{$out=$pdb}		 
#  $yesh="";			
#  if ($lsl eq "yes"){$yesh=`ls $out.dssp`}
#  if ($yesh eq ""){system "/usr/pub/molbio/dssp/dssp $out.pdb $out.dssp"
if ($struc eq "y"){
  foreach $l (`cat $e[1]`){
    if ($l=~/^  \#  RESIDUE AA STR/){$rec="y";next}
    if ($rec eq "y"){
      $a=substr ($l,13,1);
      if ($a eq "!"){
	  $war=$war."NOTE: chain break around position $csq, predictions in the area might be less relieable\n";
	  next;
      }
      $s=substr ($l,16,1);
      $ac=substr ($l,35,3);
      $ac=-(-$ac);
      $s1="0";$s2="0";$s3="0";
      if (($s eq "G") or ($s eq "H") or ($s eq "I")){$s1=100}
      if (($s eq "E") or ($s eq "B")){$s2=100}
      if (($s eq "L") or ($s eq "S") or ($s eq "T") or ($s eq "") or ($s eq " ")){$s3=100}
      $seq=$seq.$a;$csq++;
      $ss=$ss."$s1 $s2 $s3,";
      $acc=$acc."$ac,";
    }
  }
}
#  open (DS,">$out.f");
#  print DS ">$out fasta\n$seq\n";
#  close (DS,">$out.f");
#  $yesh="";
#  if ($lsl eq "yes"){$yesh=`ls $out.hssp`}
#  if ($yesh eq ""){
#    print "/home/rost/pub/maxhom/scr/maxhom.pl $out.f\n";
#    system "/home/rost/pub/maxhom/scr/maxhom.pl $out.f";
#}
#}
print "struc=$struc\n";
if ($struc eq "n"){
#  $sfile=$e[1];
#  $yesh="";
#  if ($lsl eq "yes"){$yesh=`ls $sfile.hssp`}
#  print "yesh=$yesh\n";
#  if ($yesh eq ""){system "/home/rost/pub/maxhom/scr/maxhom.pl $sfile"}
#  $yesh="";
#  if ($lsl eq "yes"){$yesh=`ls $sfile.rdbProf`}
#  if ($yesh eq ""){system "/home/rost/pub/prof/prof $sfile.hssp both"}
    foreach $l (`cat $e[1]`){
	if ($l=~/^No	AA/){
	    @tit=split(/\s+/,$l);
	    for ($i=0;$i<scalar @tit;$i++){
		if ($tit[$i] eq "AA"){$AA=$i}
		if ($tit[$i] eq "OtH"){$H=$i}
		if ($tit[$i] eq "OtE"){$E=$i}
		if ($tit[$i] eq "OtL"){$L=$i}
		if ($tit[$i] eq "PACC"){$ACC=$i}
	    }
	}
	if (($l!~/^\#/) and ($l!~/^No/)){
	    @a=split(/\s+/,$l);
	    $seq=$seq.$a[$AA];
	    $ss=$ss."$a[$H] $a[$E] $a[$L],";
	    $acc=$acc."$a[$ACC],";
	}
    }
}		      
$read="n";$readseq=2;
if ($struc eq "y"){$hssp="$out.hssp$Fil";$readseq=0}
else{$hssp="$sfile.hssp$Fil"}
foreach $l (`cat $e[0]`){
  if ($l=~/^\sSeqNo\sPDBNo/){$read="y";next}
  if (($l=~/^\#\# INSERTION LIST/) or ($l=~/^\/\//)){last}
  if ($l=~/^\#\# ALIGNMENTS/){$readseq++;next}
  if ($l=~/SeqNo  PDBNo AA STRUCTURE/){next}
  if ($read eq "y"){
    $prf=substr ($l,13,79);
    $prf=~s/^\s+//;
    $seqh=$seqh."$prf,";
    $w=substr ($l,124,6);
    $w=-(-$w);
    $wgt=$wgt."$w,";
    $sl++;
  }
}

#print "Sequence: ".length $seq."\n guy seq: $sl\n";
if (length $seq!=$sl){die "seq=$seq csq=$csq sl=$sl not same length\n"}
$sam1=1;
$st1=1;
###########################################################
#print "seq=$seq\n";
@{$a{hs}}=split (//,$seq);
@{$a{ss}}=split (/,/,$ss);
@{$a{acc}}=split (/,/,$acc);
@{$a{wgt}}=split (/,/,$wgt);
@{$a{prof}}=split (/,/,$seqh);
$c=0;
for ($i=0;$i<scalar @{$a{hs}};$i++){
  $seq="";$prf="";
  for ($j=-4;$j<5;$j++){
    if (($j+$i)<0){$prf=$prf."$empty";$seq=$seq."Z"}
    elsif (($i+$j)>=scalar @{$a{hs}}){$prf=$prf."$empty";$seq=$seq."Z"}
    else{
      $seq=$seq."$a{hs}[$i+$j]";
      $prf=$prf."$a{prof}[$i+$j] ";
    }
    #print "i=$i j=$j i+j=",$i+$j," prf=$prf\n";
  }
  $list{seq}[$c]=$seq;
  $list{ss}[$c]=$a{ss}[$i];
  $list{acc}[$c]=$a{acc}[$i];
  $list{wgt}[$c]=$a{wgt}[$i];
  $list{prof}[$c]=$prf;
  $list{pos}[$c]=$i;
  $c++;
}
###########################################################
for ($i=0;$i<scalar @{$list{seq}};$i++){
  undef @sam;undef @samseq;
  $seq=$list{seq}[$i];
  @a=split (//, $seq);#print "empty acid=@acid\n";
  @acid=split (/\s+/,$list{prof}[$i]);#print "full acid=@acid\n";
  push (@sam, @acid);
  @ss=split (/\s+/, $list{ss}[$i]);
  for ($notx=0;$notx<3;$notx++){
    if ($ss[$notx] eq ""){die "list{ss}[$i]=$list{ss}[$i] $i: ss[$notx]=$ss[$notx]\n"}
    else{$ss[$notx]=$ss[$notx]}
  }
  push (@sam,@ss);
  @ACC=("0","0","0");
  if (($i>0) and ($list{acc}[$i-1] ne "X")){$ACC[0]=int ($list{acc}[$i-1]/3)}
  if ($list{acc}[$i] ne "X"){$ACC[1]=int ($list{acc}[$i]/3)}
  if (($i<=scalar @{$list{acc}}) and ($list{acc}[$i+1] ne "X")){
    $ACC[2]=int ($list{acc}[$i+1]/3);
    if ($ACC[2]==0){$ACC[2]="0"}
  }
  push (@sam,@ACC);

  @WGT=("0","0","0");
  if (($i>0) and ($list{wgt}[$i-1] ne "X")){$WGT[0]=int (50*$list{wgt}[$i-1])}
  if ($list{wgt}[$i] ne "X"){$WGT[1]=int (50*$list{wgt}[$i])}
  if (($list{wgt}[$i+1] ne "X") and ($i<=scalar @{$list{wgt}})){
    $WGT[2]=int (50*$list{wgt}[$i+1]);
    if ($WGT[2]==0){$WGT[2]="0"}
  }
  push (@sam,@WGT);
################################################################################################
  printf I1 "%6s %8d\n","ITSAM: ",$st1;printf I1S "%6s %8d\n","ITSAM: ",$st1;
  printf O1 "%8d ", $st1;
  print MAP "$st1 $list{pos}[$i] $list{seq}[$i] $list{ss}[$i] ";
  print MAP "@ACC @WGT $list{pp}[$i]\n";
  $aa=substr ($list{seq}[$i],4,1);
  $byP[$st1]="$aa";
  $check="$sam1 $list{pos}[$i] $list{seq}[$i] $list{ss}[$i] ";
  $check=$check."@ACC @WGT";
  @ck=split(/\s+/, $check);
  if (scalar @ck!=12){die "scalar ck!=15 ck=@ck\nACC=@ACC\nWGT=@WGT\n"}
  $sam1++;$st1++;
  $d125=1;$d1s25=1;
  if (scalar @sam!=189){die "i=$i seq=$seq scalar @sam=",scalar @sam,"\n"}
  foreach $a (@sam){
    if ($d125==26){print I1 "\n";$d125=1}
    printf I1 "%6s",$a;
    $d125++;
  }
  foreach $a (@samseq){
    if ($d1s25==26){print I1S "\n";$d1s25=1}
    printf I1S "%6s",$a;
    $d1s25++;
  }
  @pp=(100,0);
  print I1 "\n";print I1S "\n";
  foreach $o (@out){printf O1 "%6s",$o}
  print O1 "\n";
}
################################################################################################
print I1 "//\n";

close (I1, ">$dirIsis/tin_forTest$sfile");
close (O1, ">$dirIsis/tout_forTest$sfile");
$st1--;

open (I1, ">$dirIsis/in_forTest$sfile")||
    die "-*- Could not open $dirIsis/in_forTest$sfile\n-*- System Err:$!\n";
print I1 "* overall: (A,T25,I8)\n";
print I1 "NUMIN                 :      189\n";
printf I1 "%23s %8d\n","NUMSAMFILE            :",$st1;
print I1 "*\n";
print I1 "* samples: count (A8,I8) NEWLINE 1..NUMIN (25I6)\n";
@ARGV="$dirIsis/tin_forTest$sfile";
while (<>){print I1 $_}
`rm $dirIsis/tin_forTest$sfile`;
close (I1, ">$dirIsis/in_forTest$sfile");
################################################################################################
open (O1, ">$dirIsis/out_forTest$sfile")||
        die "-*- Could not open $dirIsis/out_forTest$sfile\n-*- System Err:$!\n";
print O1 "* overall: (A,T25,I8)\n";
print O1 "NUMOUT                :        2\n";
printf O1 "%23s %8d\n","NUMSAMFILE            :",$st1;
print O1 "*\n";
print O1 "* samples: count (I8) SPACE 1..NUMOUT (25I6)\n";
@ARGV="$dirIsis/tout_forTest$sfile";
while (<>){print O1 $_}
`rm $dirIsis/tout_forTest$sfile`;
close (O1, ">$dirIsis/out_forTest$sfile");
################################################################################################
open (TES, ">$dirIsis/parTest$sfile") ||
        die "-*- Could not open $dirIsis/parTest$sfile\n-*- System Err:$!\n";
print TES "* I8
NUMIN                 :      189
NUMHID                :       50
NUMOUT                :        2
NUMLAYERS             :        2
NUMSAM                :";
printf TES "%9d\n",$st1;printf "%9d\n",$st1;
print TES "NUMFILEIN_IN          :        1
NUMFILEIN_OUT         :        1
NUMFILEOUT_OUT        :        1
NUMFILEOUT_JCT        :        1
STPSWPMAX             :        0
STPMAX                :        0
STPINF                :        1
ERRBINSTOP            :        0
BITACC                :      100
DICESEED              :   100025
DICESEED_ADDJCT       :        0
LOGI_RDPARWRT         :        1
LOGI_RDINWRT          :        0
LOGI_RDOUTWRT         :        0
LOGI_RDJCTWRT         :        0
* --------------------
* F15.6
EPSILON               :        0.010000
ALPHA                 :        0.300000
TEMPERATURE           :        1.000000
ERRSTOP               :        0.000000
ERRBIAS               :        0.000000
ERRBINACC             :        0.200000
THRESHOUT             :        0.500000
DICEITRVL             :        0.100000
* --------------------
* A132
TRNTYPE               : ONLINE
TRGTYPE               : SIG
ERRTYPE               : DELTASQ
MODEPRED              : sec
MODENET               : 1st,unbal
MODEIN                : win=5,loc=aa
MODEOUT               : KN
MODEJOB               : mode_of_job
FILEIN_IN             : $dirIsis/in_forTest$sfile
FILEIN_OUT            : $dirIsis/out_forTest$sfile
FILEIN_JCT            : $dirIsis/jctAuto9newHssp990-51
FILEOUT_OUT           : $dirIsis/outresultsTest990-$sfile
FILEOUT_JCT           : jct_crap
FILEOUT_ERR           : NNo_tst_err.dat
FILEOUT_YEAH          : NNo-yeah1637.tmp
//\n";
close (TES, ">$dirIsis/parTest$sfile");
system "$dirIsis/NetRun9.LINUX $dirIsis/parTest$sfile";
######################################################################
################# RECORD PREDICTIED ###################
#$out_res="/home/ofran/for/byprot/lab-seq/outresultsTest990-$sfile";
$out_res="$dirIsis/outresultsTest990-$sfile";

$ct=0;
foreach $l (`cat $out_res`){
  if ($l=~/^\s+\d/){
    chop $l;
    @a=split(/\s+/, $l);
    $pos=$a[1];
    $prval[$pos]=$a[3]-$a[2];
    $aa=$byP[$a[1]];
    if ((($a[3]-$a[2])>$g) and (($a[3]-$a[2])<$topgap)){
      $pr[$pos]="pp";
      if ($a[3]-$a[2]>18){$pr[$pos]="PP"}
      $pp++;
    }
    else{$pr[$pos]="notpp";$np++}
    $s[$pos]=$aa;
  }
}
print "pred pp=$pp np=$np scalar s=",scalar @s,"\n";
#########################################################
for ($i=0;$i<scalar @pr;$i++){
  for ($j=(-$sch);$j<$sch+1;$j++){
    if ((($i+$j)>-1) and (($i+$j)<scalar @pr)){
      if (($pr[$i+$j] eq "pp") or ($pr[$i+$j] eq "PP")){
	$prp[$i]++;
	$sprp[$i]=$sprp[$i]+$prval[$i+$j];
      }
      if ($prval[$i+$j]>=$g){$stval[$i]=$stval[$i]+$prval[$i+$j]}
    }
  }
  if (($pr[$i] eq "pp")and (($prp[$i]>$cr-1) or ($sprp[$i]>2.88571*$crd*10))){
    $out{pp}[$i]="P";
    $cpp++;
  }
  elsif ($prp[$i]<$cr){$out{pp}[$i]="-"}
  else{$out{pp}[$i]="-"}
  if ($pr[$i] eq "PP"){$out{pp}[$i]="P";$cpp++}
}
$blk=0;$seq="";$pp="";
print "         10        20        30        40\n";
if ($war ne ""){print OUT "$war"}
print OUT "1234567890123456789012345678901234567890\n";
for ($i=1;$i<scalar @s;$i++){
  $blk++;
  if ($blk==41){
    printf "%40s\n%40s\n\n",$seq,$pp;
    printf OUT "%40s\n%40s\n\n",$seq,$pp;
    $blk=1;$seq="";$pp="";
  }
  $seq=$seq.$s[$i];
  $pp=$pp."$out{pp}[$i]";
}
print "$seq\n$pp\n\n";
printf OUT "$seq\n$pp\n\n";
for ($i=0;$i<scalar @pr;$i++){
 # print "$i $s[$i] $prval[$i]\n";
  print OUT "$i $s[$i] $prval[$i]\n";
}
`rm $dirIsis/*$sfile*`;
`rm NN*`;
`rm jct_crap`;
