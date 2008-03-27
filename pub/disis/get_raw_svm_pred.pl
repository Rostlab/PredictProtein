#!/usr/bin/perl
# Yanay Ofran Venkatesh Mysore
# June 30, 2005

# This script uses the "$INPUT_DIR/prof/$sfile.rdbProf" and
# "$INPUT_DIR/hssp/$sfile.hssp" files of the given protein "$sfile"
# to create the file "$OUTPUT_DIR/$sfile-svm_in_forTest". It then runs
# the SVM "$SVM_MODEL_FILE" on that file, to produce the output file
# "$OUTPUT_DIR/$sfile.svm-raw" which contains the raw predictions of
# the SVM.

#/home3/peng/work/sp-human/bindornot.dat

# READ COMMAND-LINE PARAMETERS:
if (@ARGV<6)
{die "Usage: $0 input-dir protein-name output-dir SVM-model\n"}
@e=@ARGV;
$INPUT_DIR = $e[0];
$sfile = $e[1];
$OUTPUT_DIR = $e[2];
$SVM_MODEL_FILE = $e[3];
$hssp=$e[4];
$prof=$e[5];
#print "hssp=$hssp prof=$prof\n";
### These parameters are not used -- NO post-processing is done.
$g=$e[4];#diff between output nodes
$sch=$e[5];#half stretch
$cr=$e[6];#crowd
$nitr=$e[7];
$crgs=1;#crowd of gs
$topgap=101;#maximal difference between outputnodes

#if ($sfile=~/\.f/){
#    $tmp=$sfile;
#    if ($sfile=~/^\/data/){($b,$sfile)=split (/Pdb\//,$sfile);print "sfile=$sfile\n"}
#    chop $sfile;chop $sfile;`cp $tmp $sfile`;
#}
$cpp=0;
$lsl="yes";

#$SVM_DIR = "/home/mysore/work/DNA-bind/SVM/PERL_SCRIPTS/PAPER/svm_light";
#$SVM_DIR = "/home/nair/pub/svm-light";
$SVM_DIR = "nfs/data5/users/ppuser/server/pub/LOCtarget_v1/svm-light/";

#print "\n INPUT: $INPUT_DIR/hssp/$sfile.hssp and $INPUT_DIR/prof/$sfile.rdbProf ; OUTPUT: $OUTPUT_DIR/$sfile.svm-raw ;
#UNUSED PARAMS: stretch=$sch , crowd_predictions=$cr , crowd_gs=$crgs , gap=$g , top_gap=$topgap , itr=$nitr\n";
#############################################################
open (I1, ">$OUTPUT_DIR/$sfile-tin_forTest.tmp");
open (O1, ">$OUTPUT_DIR/$sfile-tout_forTest.tmp");
open (MAP, ">$OUTPUT_DIR/$sfile-map_forTest.tmp");

$empty="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ";

#foreach $l (`cat $sfile`){if ($l=~/^>/){chop $l;print OUT $l;last}}

print OUT ": stretch=$sch crowd_predictions=$cr gap=$g itr=$nitr\n"; # ???

foreach $l (`cat $prof`){
    if ($l=~/^No\s+AA/){
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

#print "after rdb prof seq=$seq\n";
$read="n";$readseq=2;
#$hssp="$sfile.hssp$Fil";
foreach $l (`cat $hssp`){
    if ($l=~/^\sSeqNo\sPDBNo/){$read="y";next}
    if (($l=~/^\#\# INSERTION LIST/) or ($l=~/^\/\//)){last}
    if ($l=~/^\#\# ALIGNMENTS/){$readseq++;next}
    if ($l=~/SeqNo  PDBNo AA STRUCTURE/){next}
    if ($read eq "y"){
        $prf=substr ($l,13,79);
        $prf=~s/^\s+//;
        @tt=split (/\s+/,$prf);
        if (scalar @tt!=20){print "AHHHHHHHHHHHHH ", scalar @tt,"\n"}
        $seqh=$seqh."$prf,";
        $w=substr ($l,124,6);
        #print "$l w=$w\n";
        $w=-(-$w);
        $wgt=$wgt."$w,";
        $sl++;
    }
}
if (length $seq!=$sl){die "seq=$seq csq=$csq sl=$sl not same length\n"}
$sam1=1;
$st1=1;
###########################################################
print "seq=$seq\n";
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
  if ($seq=~/XXXX/){next}
  $list{seq}[$c]=$seq;
  $list{ss}[$c]=$a{ss}[$i];
  $list{acc}[$c]=$a{acc}[$i];
  $list{wgt}[$c]=$a{wgt}[$i];
  $list{prof}[$c]=$prf;#print "list{prof}[$c]=$list{prof}[$c] prf=$prf\n";
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

close (I1, ">$OUTPUT_DIR/$sfile-tin_forTest.tmp");
close (O1, ">$OUTPUT_DIR/$sfile-tout_forTest.tmp");
$st1--;

open (I1, ">$OUTPUT_DIR/$sfile-in_forTest.tmp");
print I1 "* overall: (A,T25,I8)\n";
print I1 "NUMIN                 :      189\n";
printf I1 "%23s %8d\n","NUMSAMFILE            :",$st1;
print I1 "*\n";
print I1 "* samples: count (A8,I8) NEWLINE 1..NUMIN (25I6)\n";
@ARGV="$OUTPUT_DIR/$sfile-tin_forTest.tmp";
while (<>){print I1 $_}
`rm $OUTPUT_DIR/$sfile-tin_forTest.tmp`;
close (I1, ">$OUTPUT_DIR/$sfile-in_forTest.tmp");
################################################################################################
open (O1, ">$OUTPUT_DIR/$sfile-out_forTest.tmp");
print O1 "* overall: (A,T25,I8)\n";
print O1 "NUMOUT                :        2\n";
printf O1 "%23s %8d\n","NUMSAMFILE            :",$st1;
print O1 "*\n";
print O1 "* samples: count (I8) SPACE 1..NUMOUT (25I6)\n";
@ARGV="$OUTPUT_DIR/$sfile-tout_forTest.tmp";
while (<>){print O1 $_}
`rm $OUTPUT_DIR/$sfile-tout_forTest.tmp`;
close (O1, ">$OUTPUT_DIR/$sfile-out_forTest.tmp");
########################### SVM ################################
print "got here!!!!!!!!!!!!!!!\n";
$SVM_OUTPUT_FILE = "$OUTPUT_DIR/$sfile.svm-raw.tmp";
print "1 perl /nfs/data5/users/ppuser/server/pub/disis/changeNN2SVM.pl $OUTPUT_DIR/$sfile-in_forTest.tmp > $OUTPUT_DIR/$sfile-svm_in_forTest.tmp\n";
system "perl /nfs/data5/users/ppuser/server/pub/disis/changeNN2SVM.pl $OUTPUT_DIR/$sfile-in_forTest.tmp > $OUTPUT_DIR/$sfile-svm_in_forTest.tmp";
#call SVM:
print "/$SVM_DIR/svm_classify $OUTPUT_DIR/$sfile-svm_in_forTest.tmp $SVM_MODEL_FILE $SVM_OUTPUT_FILE\n";
system "/$SVM_DIR/svm_classify $OUTPUT_DIR/$sfile-svm_in_forTest.tmp $SVM_MODEL_FILE $SVM_OUTPUT_FILE";

################# RECORD PREDICTIED ###################
system "cat $hssp | grep SEQLENGTH";
system "cat $prof | grep \"# VALUE    PROT_NRES\"";
system "cat $OUTPUT_DIR/$sfile.svm-raw.tmp | grep -c \".\"";
printf "\n___________________________________________\n";
