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
$par{'jobId'}       =$tag;
$par{'dirMod'}     =$par{'dirHome'}."db/"; # dir in which the model files are found.
$par{'exeSVM'}     =$par{'dirHome'}."svm-light/svm_classify";# the C SVM executable
$par{'fileRes'}    ="SvmRes";
$par{'netType'}    ='"ExtNet","CytNet","NucNet","MitNet"';

$par{'protId'}     ="protId";
$par{'dirList'}    ='"SeqStrNtCompPro"';
$par{'fileComp'}   ="SeqStrNtCompPro";
$par{'svm-in'}     ="TSTi-tst-in.dat"; #the test input file
$par{'svm-out'}    ="tst-out.dat"; #the test output file
$par{'svm-id'}     ="tst-id.dat"; #id's of tst proteins.
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
  print  "given input compo file runs SVM\n";
  print STDERR "Input:scr mul-fasta\n";
  exit;
}




foreach $i (0..$#ARGV){

  $data=$ARGV[$i];

  if($data !~ /=/){
    print "wrong format for data\n";
    #    exit;
    next;
  }

  @tmp=split(/=/,$data);
  if(defined $par{$tmp[0]}){
    $par{$tmp[0]}=$tmp[1];
  }

}



#append jobId to output files
$par{'svm-in'}.=  $par{'jobId'};
$par{'svm-out'}.= $par{'jobId'};
$par{'svm-id'}.=  $par{'jobId'};
$par{'fileRes'}.= $par{'jobId'};


print STDERR "dirMod=$par{'dirMod'}\n";
#end appending



&svmMake($par{'fileComp'});



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

open($fhout,">".$fileRes) || eval {print STDERR "could not open $fileRes\n"; exit;};
print $fhout "#out gen by $0\n";#the final prediction output for all seq
print $fhout "#id\tloci\tprediction strength\n";

#now run SVM
foreach $fileList (eval $par{'dirList'}){ # only SeqComp as of now
 

  undef %predStr;

  foreach $netType (eval $par{'netType'}){# different pairwise SVM's.

    $netType=~m/^(\w{3})/;
    $predType= $conv{$1}; #the type of loci prediction to be made


    undef @res;

      
    $j=0;

    $modelFile= $par{'dirMod'}.$fileList."/".$netType."/"."model.dat";

    if(!-e $modelFile){
      print STDOUT "modelFile=$modelFile could not be found for netType=$netType\n";
      exit;
    }
    if(-e $par{'svm-out'}){#out file present from last run

      system("rm $par{'svm-out'}");
    }

    system("$par{'exeSVM'} $par{'svm-in'} $modelFile  $par{'svm-out'}");

    open($fhin,$par{'svm-out'}) || eval {print STDOUT "could not open $par{'svm-out'}\n";exit; };
    while(<$fhin>){

      s/\s+//g;
      $res[$j]=0 if (! defined $res[$j]);
      $res[$j]+=$_; #prediction using i'th model file
      $j++;# j is index for seq no
    }

    
    #now sum over results to get final pairwise pred
    
    foreach $ind (0..$#res){# $ind is no of seq

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

      print $fhout "$par{'protId'}\t$predLoc\t$predStr\n";

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


#=================================================================
#svmMake       formats data for input to neural network
#=================================================================
sub svmMake {
  
  my($res_data)=@_;
  my($NET,$var,$fileout,$fileout_ext,$fileout_ext_id,$tmp,$data,$t,$netIn,$numsam,$count,$true,$false,$ind,$it,@res,@tmp,$aa,$rem,$div);
  my($fhin,$fhout,$fhoute,$fhouti);

  $fhin=   "FHIN";
  $fhout=  "FHOUT";
  $fhoute=  "FHOUTEXT";		#handle for file containing extracell or not.
  $fhouti=  "FHOUTID";		#handle for file contain prot_id for ITSAM.

  print STDERR "input file $res_data\n";


  $var= "tst";
    
  $fileout=     $par{'svm-in'};
  $fileout_ext=   $par{'svm-out'};
  $fileout_id=    $par{'svm-id'};


  open($fhin,$res_data) || eval {print STDOUT "**** can't open input file =$res_data\n"; exit;};

  while (<$fhin>) {
    
    next if ($_=~ /^\#/);
    @tmp=split(/[\s]+/,$_);
    $data= $_;			# saves residue info	   
    $t++;
    $bin_t[$t]= "$_";
  }

  close($fhin);


  # find number of input units to neural net
  @tmp= split(/[\s]+/,$bin_t[1]);
  $netIn= $#tmp - 3; 		# for the 4 initial prot info columns

  $numsam= $t;


  open($fhout,">".$fileout) || die print "**** failed opening out file=$fileout\n";
  
  print $fhout "# Input file for SVM lite\n";
  print $fhout "# output from $scr                               *\n"; 
  print $fhout "#      -----------------------------------------------------------------       *\n";
 
   open($fhoute,">".$fileout_ext) || die "**** can't open out file = $fileout_ext\n";
   print $fhoute "#      -----------------------------------------------------------------       #\n";
  print $fhoute "#out gen by $scr\n";

  print $fhoute "#      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                 *\n";
  open($fhouti,">".$fileout_id) || die print "**** can't open out file = $fileout_id\n";

  print $fhouti "#      -----------------------------------------------------------------       *\n";
  print $fhouti "#out gen by $scr\n";
  print $fhouti "#      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                 *\n";



  # start reading input

 

  $count=1;			# counts in_prot number. same as ITSAM no.
  #------------------------------------------------------------------------
  $true=1; 
  #$true= 90;
  $false=-1;			# var for true if loc=ext, false if not
  #$false=10;

  #-----------------------------------------------------------------------

  $ind=0;

  while ($count<=$numsam) {
    $ind++;
    @tmp=split(/[\s]+/,$bin_t[$ind]);
	

    print $fhouti "$count\t$tmp[0]\t$tmp[1]\n";


    print $fhout "$false";
    print $fhoute "$count\t$false\n";

    print STDOUT "$count\t$false\n";
    
    @res = (0) * $netIn;
    
    foreach $it (4..$#tmp) {
	  
      $res[$it-4]= $tmp[$it]; # for non-PCA nets
    }
        
    #now normalize
    #$len=0;
    #foreach $aa (0..$#res){

     # $len+= $res[$aa]**2;
    #}

    #$len= sqrt $len;

    foreach $aa (0..$#res){

      #$res[$aa]=round (10000*$res[$aa]/$len)/10000;
      $res[$aa]=$res[$aa]/100;# input raw probabilities
    }
    
    foreach $aa (0..$#res) {
      $featNo=$aa+1;
      next if ($res[$aa]==0);
      print $fhout "\t$featNo:$res[$aa]";
       print STDOUT "\t$featNo:$res[$aa]";
      
    }
    $count++;
    print $fhout "\n";

  }



}
