#! /usr/bin/perl -w

## scr to predict loci for Heirarchical networks using SVM!

$fhin= "FHIN";
$fhdata= "FHDATA";
$fhErr= "FHERR";

$fhout="FHOUT";
$fhout1="FHOUT1";

$tag= int (rand 10000); # random tag assigned to past outputs!
$scr=$0;
$scr=~m /^(.*\/).*?/;


$dir{'scr'}        ="$1";

$scr{'makeComp'}   =$dir{'scr'}."makeComp.pl";
$scr{'combComp'}   =$dir{'scr'}."combComp.pl";
$scr{'testHr'}     =$dir{'scr'}."svm_test.pl";
$scr{'runMaxf'}    =$dir{'scr'}."maxf.pl";
$scr{'exeSVM'}     =$dir{'scr'}."svm-light/svm_classify";# the C SVM executable

$par{'jobId'}        =$tag;
$par{'dirOut'}     ="./";#the dir in which results are found!!
$par{'dirCompo'}   ="./";# the dir with Compo files
#$par{'dirTop'}     ="/misc/magnolia2/nair/work/proj_loci_swiss/Heirarchical/Level1/"; #the top level of heirarchy
$par{'dirMod'}     = $dir{'scr'}."db/";
$par{'fileRes'}    ="LociPred-svm.rdb";
$par{'fileErr'}    ="svmPred_Err.rdb";
$par{'protId'}     ="protId";


$par{"fileFasta"}="protId.f";#fasta file!
$par{"fileHssp"}= "protId.hssp";#file filtered hssp files, used to cal profiles.
$par{"fileProf"}="protId.rdbProf"; #file with PPROF output.

$par{'fileOutSeqPro'}= $par{"dirOut"}."SeqCompPro";
$par{'fileOutPhdExpPro'}= $par{"dirOut"}."PhdExpCompPro";
$par{'fileOutNtermPro'}=$par{"dirOut"}."NtermCompPro";
$par{'fileOutPhdBigPro'}= $par{"dirOut"}."PhdBigCompPro";
$par{'fileOutCompNt'}  = "SeqStrNtCompPro"; #the compoFile to be created!


if($#ARGV <0){
  print STDERR "use:scr list(proteins) on which SVM is to be run\n";
  print $fhErr "use:scr list(proteins) on which SVM is to be run\n";
  exit;
}


foreach $i (0..$#ARGV){

  if($ARGV[$i]=~ /(.*)=(.*)/){
    $arg=$1;
    $val=$2;
    print "arg=$1\tval=$2\n";
    if(defined $par{$arg}){# accepted argument!
      $par{$arg}=$val;
      print STDERR "$arg set to $val\n";
    }
    else{#input not right
      print STDERR "unacceptable argument $arg\n check input\n";
      exit;
    }

  }
  else{
      print STDERR "unacceptable input\nno arguments provided\n";
      exit;

  }

}


foreach $comp (keys %par){
  if($comp=~/fileOut/){
    $par{$comp}.=$par{'jobId'};
  }

}

open($fhErr,">".$par{'fileErr'})|| die "could not open $par{'fileErr'}\n";
print $fhErr "#out gen by $0\n";


#run MaxHom and Prof if files not found!!!!
if(!-e $par{"fileHssp"} || !-e $par{"fileProf"}){
  $par{'fileHssp'}=$par{'protId'}.".hssp".$par{'jobId'};
  $par{'fileProf'}=$par{'protId'}.".rdbProf".$par{'jobId'};
  print "XX\n";
  system("$scr{runMaxf} protId=$par{'protId'} fileFasta=$par{'fileFasta'} fileHssp=$par{'fileHssp'} fileProf=$par{'fileProf'}");

}

system("$scr{'makeComp'} protId=$par{'protId'} fileHssp=$par{'fileHssp'} fileProf=$par{'fileProf'} jobId=$par{'jobId'}") ;

#check if compo files exist ..also chech if SignalP rdb file is present!!!

if(!(-e $par{'fileOutSeqPro'})){

  print STDERR "outfile= $par{'fileOutSeqPro'} not found!\n";
  print $fhErr "outfile= $par{'fileOutSeqPro'} not found!\n";
  exit;
}


if(!(-e $par{'fileOutPhdExpPro'})){

  print STDERR "outfile= $par{'fileOutPhdExpPro'} not found!\n";
  print $fhErr "outfile= $par{'fileOutPhdExpPro'} not found!\n";
  exit;
}

if(!(-e $par{'fileOutNtermPro'})){

  print STDERR "outfile= $par{'fileOutNtermPro'} not found!\n";
  print $fhErr "outfile= $par{'fileOutNtermPro'} not found!\n";
  exit;
}

if(!(-e $par{'fileOutPhdBigPro'})){

  print STDERR "outfile= $par{'fileOutPhdBigPro'} not found!\n";
  print $fhErr "outfile= $par{'fileOutPhdBigPro'} not found!\n";
  exit;
}

#system("$scr{'findSigp'} $fileIn $par{'dirSig'}"); #process SignalP output!

#now run CombComp

system("$scr{'combComp'} $par{'fileOutCompNt'} $par{'fileOutSeqPro'} $par{'fileOutPhdBigPro'} $par{'fileOutNtermPro'}");

if(!(-e $par{'fileOutCompNt'})){

  print STDERR "compo file $par{'compoNt'} not found\n";
  print $fhErr "compo file $par{'compoNt'} not found\n";
  exit;

}



#now run test scr for predictions!!!

system("$scr{'testHr'} fileComp=$par{'fileOutCompNt'} protId=$par{'protId'} dirMod=$par{'dirMod'} jobId=$par{'jobId'}");

