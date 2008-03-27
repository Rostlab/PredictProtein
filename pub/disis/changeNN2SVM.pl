#!/usr/bin/perl
@e = @ARGV;
if (@ARGV < 1) { die "usage: perl changeNNtoSVM.pl <input_file> [<classification_file>]";}
$INPUT_FILE = @e[0];
$CLASS_FILE = @e[1];
$path="/home/ofran/";
if ($CLASS_FILE ne ""){
    foreach $l (`cat $CLASS_FILE`){
        if ($l=~/^\s+\d/){
            @a=split (/\s+/,$l);
            $out[$a[1]]=$a[3];
        }
    }
}
#print "here++++++++++++\n";
foreach $l (`cat $INPUT_FILE`){
  if ($l=~/^[N|\*]/){next}
  chop $l;
  if (($l=~/ITSAM/) or ($l=~/\/\//)){
    @a=split (/\s+/,$ln);
    $ln="";
    if ($out[$it]==100){$cl=1}
    else{$cl=-1}
    if ($it>0){print "$cl ";}
    for ($i=0;$i<190;$i++){if ($a[$i]!=0){print "$i:$a[$i] "}}
    if ($it>0){print "\n"}
    ($b,$it)=split(/\s+/,$l);
  }
  else{$ln=$ln.$l}
}
