#! /usr/bin/perl -w
##Perl wrapper to generate statistics over all split dir.

#input files: 
#output files: 


print "#running scr $0\n";

$fhin= "FHIN";
$fhdata= "FHDATA";

$fhout="FHOUT";
$fhout1="FHOUT1";

$tag= int (rand 10000); # random tag assigned to past outputs!

$scr=$0;
$scr=~m /^(.*\/).*?/;

$par{'dirHome'}    =$1;
$par{'tag'}        =$tag;
$par{'nset'}       = 1;# nfold cross validation;
$par{'modDir'}     =$par{'dirHome'}."db/"; # dir in which the model files are found.
$par{'exeSVM'}     =$par{'dirHome'}."svm-light/svm_classify";# the C SVM executable
$par{'fileRes'}    ="svm";
$par{'netType'}    ='"ExtNet","CytNet","NucNet","MitNet"';

$par{'dirList'}    ='"SeqComp"';
$par{'svm-in'}     ="TSTi-tst-in.dat"; #the test input file
$par{'svm-out'}    ="tst-out.dat"; #the test output file
$par{'svm-id'}     ="tst-id.dat"; #id's of tst proteins.
$par{"resEle"}     = "V,L,I,M,F,W,Y,G,A,P,S,T,C,H,R,K,Q,E,N,D";
$par{"jobId"}      ="";


#==========================================================

$conv{'Ext'}="ext";$conv{'Cyt'}="cyt";$conv{'Nuc'}="nuc";$conv{'Mit'}="mit";
$conv{'Pla'}="pla"; $conv{'Ret'}="ret"; $conv{'Gol'}="gol";

#==========================================================


$fhin="FHIN";
$fhdata= "FHDATA";
$fhout="FHOUT";

$fhErr="FHERR";



if ($#ARGV <0 || $ARGV[0]=~/^(h|\?)/){
  print  "Given a multi-fasta list of test proteins calculates input composition needed for neural network\n";
  print STDERR "Input:scr mul-fasta\n";
  exit;
}




$fileIn= $ARGV[0]; # a multi-fasta file of proteins

$par{'jobId'} = $ARGV[1];

#append jobId to output files
$par{'svm-in'}.=  $par{'jobId'};
$par{'svm-out'}.= $par{'jobId'};
$par{'svm-id'}.=  $par{'jobId'};
$par{'fileRes'}.= $par{'jobId'};

#end appending

@resEle=split(/,/,$par{"resEle"});

foreach $it (@resEle){

  $allRes{$it}=0;
}

undef %fasta;

#rd multi fasta and make input file to SVM.
open($fhin,$fileIn) || eval {print "could  not open $fileIn\n";exit;};


while(<$fhin>){
  next if /^\#/;
  if(/^>/){
    if(/\|/){
      m/^>.*\|(.*?)\s/;
      $id=$1;
    }
    else{
     
      m/^>(.*?)\s/;
      $id=$1;

    }

    $fasta{$id}="";

    push @idList, $id;
    #print STDERR "***$id*****\n";
    if(!defined $id){
      print STDERR "prot id could not be extracted $_\n";
      print "prot id could not be extracted $_\n";
      exit;
    }
    next;
  }
  else{
    s/\s+//g;
    $fasta{$id}.=$_;
  }
}

#now cal compo for each seq and make the tst-in.dat file.

open($fhout, ">".$par{'svm-in'}) || eval {print "could not open $par{'svm-in'}"; exit;};
print $fhout "#out gen by $0\n";
print $fhout "#class";


foreach $it (@resEle){
  print $fhout "\t$it";
}
print $fhout "\n";#order in which the residues appear!



foreach $id (sort keys %fasta){

  print $fhout "0";#class type unknown

  @fasta=split(//,$fasta{$id});
  $resCnt=0;
  foreach $it (@fasta){
    $allRes{$it}++;
    $resCnt++;
  }

  foreach $j (0..$#resEle){
    $it=$resEle[$j];
    $featNo=$j+1;
    $allRes{$it}= round(1000*$allRes{$it}/$resCnt)/1000;
    print $fhout "\t$featNo:$allRes{$it}";
  }
  print $fhout "\n";

}

close $fhout;

#define diff prediction types.
foreach $netType (eval $par{'netType'}){
  $netType=~m/(\w{3})/;
  $net=$conv{$1};
  $locDb{$net}=1; #the types of localization def
  push @net,$net;
}

$locDb{'not'}=1;
push @net,'not';


$fileRes= $par{'fileRes'};

open($fhout,">".$fileRes) || eval {print "could not open $fileRes\n"; exit;};
print $fhout "#out gen by $0\n";#the final prediction output for all seq
print $fhout "#id\tloci\tprediction strength\n";

#now run SVM
foreach $fileList (eval $par{'dirList'}){ # only SeqComp as of now
 

  undef %predStr;

  foreach $netType (eval $par{'netType'}){# different pairwise SVM's.

    $netType=~m/^(\w{3})/;
    $predType= $conv{$1}; #the type of loci prediction to be made


    undef @res;

    foreach $i (1..$par{'nset'}){ # $i is number of model files
  
      $j=0;

      $modelFile= $par{'modDir'}.$fileList."/".$netType."/"."model-$i.dat";

      if(-e $par{'svm-out'}){#out file present from last run

	system("rm $par{'svm-out'}");
      }

      system("$par{'exeSVM'} $par{'svm-in'} $modelFile  $par{'svm-out'}");

      open($fhin,$par{'svm-out'}) || eval {print "could not open $par{'svm-out'}\n";exit; };
      while(<$fhin>){

	s/\s+//g;
	$res[$j]=0 if (! defined $res[$j]);
	$res[$j]+=$_; #prediction using i'th model file
	$j++;# j is index for seq no
      }

    }
    #now sum over results to get final pairwise pred
    
    foreach $ind (0..$#res){# $ind is no of seq

      $res[$ind]=round (100*$res[$ind]/$par{'nset'})/100;
      $predStr[$ind]{$predType}= $res[$ind];# the strength of prediction
      print  "$ind\t$predType\t$res[$ind]\n";

    }

  }

  foreach $ind (0..$#predStr){ # $ind is no of seq
    #sort by pred strength
    @sortLoc= sort {$predStr[$ind]{$b} <=> $predStr[$ind]{$a}} (keys %{$predStr[$ind]});
    $predLoc=$sortLoc[0];
    $predStr=$predStr[$ind]{$predLoc};

    if($predStr[$ind]{$predLoc} < 0){
      # predicted loci is 'not'
      $predLoc='not';
    }

      print $fhout "$idList[$ind]\t$predLoc\t$predStr\n";

  }
  
}
	

#=======================================================================

sub round {
    local($tmp)=@_;
    local($var)= $tmp;
    $dec=$var - int ($var);
    if ( abs($dec) gt .5){
	if($var>0) {
	    $var = int ($var) + 1;
	}
	else {
	    $var = int ($var)-1;
	}
	$tmp = $var;
	return ($tmp);
    }
    else{
       $tmp = int ($var); 
       return ($tmp);
    }
}

