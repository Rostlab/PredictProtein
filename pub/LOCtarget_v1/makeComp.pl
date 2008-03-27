#! /usr/bin/perl -w
## scr to calculate secondary structure composition for Swiss list.
## uses Phd Rdb output(.rdbPhd files) to calculate sequence, seconday structure and exposed residue composition!


$scr= $0;


$par{"dirOut"}= ""; # the dir in which the out files will be found

$par{"exp"}=10; # if normalised exposure gt than this the residue considered exposed.
$par{"jobId"}="";
$par{"fileLoc"}="No";# no localization file porvided ..for unknown loci test set.
$par{"protId"}="protId";
$par{"fileHssp"}= "protId.hssp";#to dir with filtered hssp files, used to cal profiles.
$par{"fileProf"}="protId.rdbProf"; #to dir with PPROF output.
$par{"compFileList"}= "No";# writes a file with list of composition files the scr made ..for use when called from nn_testFormat.pl
$par{"minLen"}=25; # min length of protein. smaller fragments discarded.
$par{"nterm"}=50; #no of nterminal residues used. For proteins shorter than 50 residues, length of protein used. 
#$par{"ide"}=0.50;# only aligned sequences with greater than 50% seq ide considered in evaluating profile based composition.
$par{"minLali"}=13;
$par{"minDist"}=4;# only aligned sequences with hssp dist greater than 4 considered in evaluating profile based composition.


$fhin= "FHIN";
$fhSeq= "FHSEQ";
$fhSeqPro= "FHPRO";

$fhNterm= "FHNTERM";
$fhNtermPro="FHNTERMPRO";
$fhPhdExp="FHPHDEXP";
$fhPhdExpPro= "FHPHDEXPPRO";
$fhList="FHLIST";

$fhPhdStr="FHPHDSTR";

$fhPhdBig="FHPHDBIG";
$fhPhdBigPro="FHPHDBIGPRO";


$fhData= "FHDATA";
$fhErr= "FHERR";



#---define sec str types-------------
$secType{"H"}= "Alpha helix"; 
$secType{"E"}= "Extended conformation";
$secType{"L"}= "Coil";

#-----------------------------------------------


#
# default exposure normalization values have been obtained from ~rost/perl/lib/prot.pl. Has sub routine convert_acc.
#   --------------------------------------------------
#   Reinhard
#   --------------------------------------------------
    
$NORM_EXP{"A"} = 106;  $NORM_EXP{"B"} =160;         # D or N
$NORM_EXP{"C"} = 135;  $NORM_EXP{"D"} =163;  $NORM_EXP{"E"} =194;
$NORM_EXP{"F"} = 197;  $NORM_EXP{"G"} = 84;  $NORM_EXP{"H"} =184;
$NORM_EXP{"I"} = 169;  $NORM_EXP{"K"} =205;  $NORM_EXP{"L"} =164;
$NORM_EXP{"M"} = 188;  $NORM_EXP{"N"} =157;  $NORM_EXP{"P"} =136;
$NORM_EXP{"Q"} = 198;  $NORM_EXP{"R"} =248;  $NORM_EXP{"S"} =130;
$NORM_EXP{"T"} = 142;  $NORM_EXP{"V"} =142;  $NORM_EXP{"W"} =227;
$NORM_EXP{"X"} = 180;         # undetermined (deliberate)
$NORM_EXP{"Y"} = 222;  $NORM_EXP{"Z"} =196;         # E or Q
$NORM_EXP{"max"}=248;

#   --------------------------------------------------


if($#ARGV <0){
  print "use:scr list(proteins),  dir with hsspFil and phdSec files  files (if not provided assumed tob e those in par)\n";
  print "output: Swiss_SeqComp, Swiss_ExpComp,Swiss_NtermComp, Swiss_PhdStrComp and Swiss_PhdStrBigComp\n";
  print "Swiss_PhdStrBigComp contains 60 units ..composition of each residue in helical, beta or loop state\n";
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




$par{'fileErr'}= "CompMaker.err";

open($fhErr, ">".$par{'fileErr'}) || die "could not open out File= $par{'fileErr'}\n";
print $fhErr "#Out gen by scr: $scr\n";
print $fhErr "#proteins for which $scr failed\n";


undef %locDb;

if($par{"fileLoc"} !~ /^No/){#localization file provided
  open($fhin, $par{"fileLoc"}) || eval{ print STDERR "$scr could not open provided loci file=$par{'fileLoc'}\nStart again!\n";
					print $fhErr "$scr could not open provided loci file=$par{'fileLoc'}\n";
					exit;
				      };
  while(<$fhin>){

    next if /^\#/;
    @tmp=split(/[\s]+/,$_);
    $id= $tmp[0];
    $locDb{$id}=$tmp[1];
  }
  
}


#-------- the output file definitions
$par{'fileOutSeq'}= $par{"dirOut"}."SeqComp".$par{"jobId"};
$par{'fileOutSeqPro'}= $par{"dirOut"}."SeqCompPro".$par{"jobId"};
$par{'fileOutPhdExp'}=$par{"dirOut"}."PhdExpComp".$par{"jobId"};
$par{'fileOutPhdExpPro'}= $par{"dirOut"}."PhdExpCompPro".$par{"jobId"};
$par{'fileOutNterm'}=$par{"dirOut"}."NtermComp".$par{"jobId"};
$par{'fileOutNtermPro'}=$par{"dirOut"}."NtermCompPro".$par{"jobId"};
$par{'fileOutPhdStr'}= $par{"dirOut"}."PhdStrComp".$par{"jobId"};
$par{'fileOutPhdBig'}= $par{"dirOut"}."PhdBigComp".$par{"jobId"};
$par{'fileOutPhdBigPro'}= $par{"dirOut"}."PhdBigCompPro".$par{"jobId"};

$fileOutDat=$par{"dirOut"}."All.sec".$par{"jobId"};

#-----------------------------------
# list of files in which all data will be deposited.
if($par{"compFileList"}!~ /^No/){
  # make a list file
  open($fhList,">".$par{"compFileList"}) || die "***could not open out file=$par{'compFileList'}\n";
  print $fhList "#out gen by $scr\n";
  @fileList=($par{'fileOutSeq'},$par{'fileOutSeqPro'},$par{'fileOutPhdExp'},$par{'fileOutPhdExpPro'},$par{'fileOutNterm'},$par{'fileOutNtermPro'},$par{'fileOutPhdStr'},$par{'fileOutPhdBig'},$par{'fileOutPhdBigPro'}) ;
  foreach $f (@fileList){
    print $fhList "$f\n";
  }
  close $fhList;
}


open($fhData,">".$fileOutDat) || die "could not open $fileOutDat\n";
print $fhData "#out gen by $scr\n";
print $fhData "#id\tseq\tsec\tacc\n";

open($fhSeq, ">".$par{'fileOutSeq'}) || die "could not open out File= $par{'fileOutSeq'}\n";
open($fhSeqPro, ">".$par{'fileOutSeqPro'}) || die "could not open out File= $par{'fileOutSeqPro'}\n";
open($fhPhdExp, ">".$par{'fileOutPhdExp'}) || die "could not open out File= $par{'fileOutPhdExp'}\n";
open($fhPhdExpPro, ">".$par{'fileOutPhdExpPro'}) || die "could not open out File= $par{'fileOutPhdExpPro'}\n";
open($fhNterm, ">".$par{'fileOutNterm'}) || die "could not open out File= $par{'fileOutNterm'}\n";
open($fhNtermPro, ">".$par{'fileOutNtermPro'}) || die "could not open out File= $par{'fileOutNtermPro'}\n";
open($fhPhdStr,">".$par{'fileOutPhdStr'}) || die "could not open out File= $par{'fileOutPhdStr'}\n";
open($fhPhdBig, ">".$par{'fileOutPhdBig'}) || die "could not open out File= $par{'fileOutBig'}\n";
open($fhPhdBigPro, ">".$par{'fileOutPhdBigPro'}) || die "could not open out File= $par{'fileOutBig'}\n";


foreach $fh ($fhSeq,$fhSeqPro,$fhNterm,$fhNtermPro){

print $fh "#Out gen by scr: $scr(xx's inserted for compatability)\n";
print $fh "#Hssp Dir =$par{'dirHssp'}\n";
print $fh "#pdb_id\txx\txx\tlen";

}

foreach $fh ($fhPhdExp, $fhPhdExpPro, $fhPhdStr, $fhPhdBig, $fhPhdBigPro){

print $fh "#Out gen by scr: $scr(xx's inserted for compatability)\n";
print $fh "#File contains \"secondary structure\" composition of each residue type\n";
print $fh "#All exposed and intermediate predicted residues assigned to exposed state\n";
print $fh "#HsspFile =$par{'fileHssp'}\n";
print $fh "#ProfFile =$par{'fileProf'}\n";
print $fh "#pdb_id\txx\txx\tlen";

}



foreach $fh ($fhSeq,$fhSeqPro,$fhPhdExp,$fhPhdExpPro,$fhNterm,$fhNtermPro){
  foreach $it ("V","L","I","M","F","W","Y","G","A","P","S","T","C","H","R","K","Q","E","N","D"){
      print $fh "\t$it";
  }
  print $fh "\n";
}



foreach $it (keys %secType){
  print $fhPhdStr "\t$it";
  foreach $x ("V","L","I","M","F","W","Y","G","A","P","S","T","C","H","R","K","Q","E","N","D"){
    foreach $fh ($fhPhdBig, $fhPhdBigPro){
      print $fh "\t$it$x";
      
    }
  }
}

foreach $fh ($fhPhdStr,$fhPhdBig, $fhPhdBigPro){
  print $fh "\n";
}



 
if (-e $par{"fileHssp"}) {
  open($fhin,$par{"fileHssp"}) || die "** could not open file=$par{'fileHssp'}\n";
  #print STDERR "HSSP file=$fileHssp\n";
} else {
  print STDERR "could not find hssp file for prot $par{'protId'} in dir $par{'fileHssp'}\n";
  print $fhErr "$par{'protId'}\tHssp file $fileHssp not found\n";
  next PROT;
}

print STDERR "proc prot= $par{'protId'}\n";

$NUM=0; 

$flag=0; $ali_flag=0;  $all_count=0 ; $ide_flag=0; 
$seqNo=0;
undef %hsspData;undef $seqLen;


RES:
while (<$fhin>) {
  $ide="";
  $aliLen="";
  $exp_in="";
  $ali_seq="";
  last RES if (/^\#\# SEQUENCE PROFILE AND ENTROPY/);

  if ($_=~ /^SEQLENGTH/) {
    $_=~m /(\d+)/;
    $seqLen=$1;
    next PROT if ($seqLen <= $par{"minLen"});
    # only prot having more than min_len residues is considered. 
    #      $hsspData{"seqLen"}=$seqLen;
  }
  if ($_=~ /^\#\#/) {
    if ($_=~ / ALIGNMENTS/) {
      print STDERR "number of algnments used to cal profile: $NUM\n";
      $flag=1;
      $ali_flag++;
    } elsif ($_=~ /PROTEINS/) {
      $flag=-1;
    } else {
      $flag=0;
    }
  }
  if ($flag==-1) {
    if ($_=~ /NR\./) {
      $_=~m /(.*)NR\./;
      @tmp=split(//,$1);
      $no_beg=$#tmp+1;
      $no_end=$#tmp+3;
      $_=~m /(.*)\%IDE/;
      @tmp=split(//,$1);
      $ide_beg= $#tmp+1;
      $ide_end= $#tmp+4;

      m/(.*)LALI/;
      @tmp=split(//,$1);
      $lali_beg= $#tmp+1;
      $lali_end= $#tmp+4;
		
    } elsif (!($_=~ /PROTEINS/)) {
      @tmp=split(//,$_);
      foreach $x ($ide_beg..$ide_end) {
	$ide=$ide.$tmp[$x];
      }
      $ide=~s /\s//g;

      foreach $x ($lali_beg..$lali_end) {
	$aliLen.=$tmp[$x];
      }

      $aliLen=~s /\s//g;
      $pid=100*$ide;
      #print STDERR "aliLen=$aliLen\tide=$ide\n";
      next if (!(defined $aliLen) || $aliLen < $par{"minLali"} );

	

      ($pideCurve,$msg)=
	&getDistanceNewCurveIde($aliLen);


      next if ($msg !~ /^ok/);
      $disNewcurve= $pid - $pideCurve;
      $disNewcurve= round ( $disNewcurve);
  

      if ($disNewcurve >= $par{"minDist"} ) {
	$NUM++;
      }
      #if($ide<$similarity && $ide_flag==0){
      # only sequences with %ide gt $similarity considered for eval profile based composition. 
      #   $ide_flag++;
      #  foreach $y ($no_beg..$no_end){
      #	$NUM=$NUM.$tmp[$y];
      #   }
      #   $NUM=~s /\s//g;
      #   $NUM--;
      # Number of Alignment with gt than 60 percent res identity.
      #   if ($NUM>70) {
      #	$NUM= 70; # only the top 70 alignments are considered in this case. This is done for simplifying scr. The rest of the alignments are repeated all over again.
      #    }
		
      if ($NUM>70) {
	$NUM= 70;		# only the top 70 alignments are considered in this case. This is done for simplifying scr. The rest of the alignments are repeated all over again.
      }
    }
  } elsif ($flag==1 && $ali_flag==1) {
	    
    if ($_=~ /SeqNo/) {
      $_=~m /^(.*SeqNo)/;
      @tmp=split(//,$1);
      $pos =$#tmp; 		 # the residue No
	
      $_=~m /(.*)AA.*/;
      @tmp=split(//,$1);
      $aa=$#tmp+1;
      
      $_=~m /^(.*?)\./;
      #print STDERR "prestring =$1\n";
      @tmp=split(//,$1);
      $res_start= $#tmp+1;
      $res_end= $#tmp+$NUM;	#only this num of aligned sequences in profile!
      next;
      
    } elsif ($_ !~ /ALIGNMENTS/) {
      #	print STDERR "$_";

      @tmp=split(//,$_);

      #	foreach $i (0..$pos){
      #	  $seqNo.=$tmp[$i];
      #	}

      #	$seqNo=~s / //g;

      next RES if ($tmp[$aa]=~ /\!|X/);

      $seqNo++;			#the total no of residues!
      $hsspData{$seqNo,"res"}=$tmp[$aa];
	
      #print STDERR "$seqNo\tres=$tmp[$aa]\n";

      foreach $y ($res_start..$res_end) { # only aligned sequences meeting certain requirements taken into consideration.
	if (defined $tmp[$y]) {
	  $ali_seq=$ali_seq.$tmp[$y];
	}
	  
      }
      
      $ali_seq=~s /\s//g;
      $ali_seq=~s /\.//g;
      
      $ali_seq=~tr /[a-z]/[A-Z]/;
      $hsspData{$seqNo,"ali"}=$ali_seq;

    }
  }
}
close($fhin);
$hsspData{"seqLen"}=$seqNo;

# ===============================================================================

undef %phdData;


 
if (-r $par{'fileProf'}) {
  open($fhin,$par{'fileProf'}) || die "** could not open file=$par{'fileProf'}\n";

} else {
  print STDERR "could not find rdbPhd file for prot $par{'protId'} in dir $par{'dirProf'}\n";
  print $fhErr "$id\tProf file not found\n";
  next PROT;
}

$seqNo=0;

PHD:	
while (<$fhin>) {
       
  if (/^\# LENGTH/ ) {
    m/(\d+)$/;
    #	$phdData{"seqLen"}=$1; # chain length rec for comparing with hssp chain length
  }
      
  next PHD if ($_=~/^\#/);

  if ($_=~ /^No/) {
	
    @tmp = split(/[\s]+/,$_);
    foreach $it (1..$#tmp) {

      if ($tmp[$it]=~ /PHEL/) {	#pred sec str
	$sec= $it;
      } elsif ($tmp[$it]=~ /PACC/) {
	$pos = $it ;		# contains column no for PACC
      } elsif ($tmp[$it]=~ /PREL/) {
	$prel= $it;
      } elsif ($tmp[$it]=~/RI_A/) {
	$ria=$it;
      } elsif ($tmp[$it]=~/Pbie/) {
	$pbie=$it;
      }
    }
  } else {
	
    s/^\s+//;
    @tmp=split(/[\s]+/,$_);

    next PHD if ($tmp[1]=~ /\!|X/);

    $seqNo++;			#the total no of residues
    $res=$tmp[1];
    $phdData{$seqNo,"res"}=$res;
    $phdData{$seqNo,"str"}= $tmp[$sec];
	
    #	print STDERR "$res\tstr=$tmp[$sec]\n";
    #	print STDERR "pbie= $pbie\t$tmp[$pbie]\t$res\n";
	
    if ($tmp[$pbie]=~/e|i/) {
      # residue is exposed
      #print STDERR "res no $seqNo is exposed!\n";
      $phdData{$seqNo,"acc"}="Exp";
    } else {
      $phdData{$seqNo,"acc"}="Bur";
    }
	
  }
      
}
$phdData{"seqLen"}=$seqNo;	# prot length rec for comparing with hssp prot length

#===================================================================================
#check if chain length's from hssp and Phd are the same!

if ($hsspData{"seqLen"} != $phdData{"seqLen"}) {
  print STDERR "Chain length from Hssp not same as chain length from Phd\n";
  print STDERR "Hssp chain length=$hsspData{'seqLen'} and Phd chain length = $phdData{'seqLen'}\n";
  print STDERR "---*start again!*----\n";
  print $fhErr "$par{'protId'}\tChain length from Hssp not same as chain length from Phd\n";
  exit;

}
      
#==========================================================================
# hssp data read! ..now processing

  
$resCnt=0;
$ntermCnt=0;
$expPhdCnt=0;
$Seq="";$Acc="";$Sec="";

foreach $it ("V","L","I","M","F","W","Y","G","A","P","S","T","C","H","R","K","Q","E","N","D") {
  $allRes{$it}=0; $allResPro{$it}=0;
  $ntermRes{$it}=0; $ntermResPro{$it}=0;
  $expPhdRes{$it}=0; $expPhdResPro{$it}=0;

}

foreach $str (keys %secType) {
  $strPhdComp{$str}=0;
  foreach $it ("V","L","I","M","F","W","Y","G","A","P","S","T","C","H","R","K","Q","E","N","D") {
    $bigPhdRes{$str.$it}=0;
    $bigPhdResPro{$str.$it}=0;
  }
}
  



PROC:
foreach $ind (1..$hsspData{"seqLen"}) {
  next PROC if (! defined $hsspData{$ind,"res"});
  $resCnt++;			# total residue count!

  if ($ind<=$par{"nterm"}) {
    $ntermCnt++;
  }

  #=============================================================================
  #the observed expt data
  $res= $hsspData{$ind,"res"};
  $Seq.=$res;
  #==============================================================================

  #    print STDERR "id=$par{'protId'}\tresNo=$ind\tres=$res\tnormAcc=$normAcc\n";

  #--------the PHD data--------------
  $phdRes=$phdData{$ind,"res"};
  $phdStr=$phdData{$ind,"str"};
  $phdAcc=$phdData{$ind,"acc"};

  $Sec.=$phdStr;
  if ($phdAcc eq "Exp") {
    $Acc.="e";
  } else {
    $Acc.="b";
  }

  #---------check PHD with HSSP!------------------------
  if ($res ne $phdRes) {
    print STDERR "Hssp and PHD have different residues for res no: $ind and protein $par{'protId'}\n";
    print STDERR "check input ..start again!\n";
    print $fhErr "$par{'protId'}\tHssp and PHD have different residues for res no: $ind\n";
    next PROT;

  }

  # ---finish check!-------------



  if (defined $hsspData{$ind,"ali"}) { # the aligned seq for profiles
    $aliSeq= $hsspData{$ind,"ali"};
  } else {
    print STDERR "aliSeq not defined!\n";
    $aliSeq="";
  }

  $allRes{$res}++;


  if ($phdAcc=~ /Exp/) {
    $expPhdRes{$res}++;
    $expPhdCnt++;
  }

  if ($ind<=$par{"nterm"}) {
    $ntermRes{$res}++;
  }

  $strPhdComp{$phdStr}++;
  $bigPhdRes{$phdStr.$res}++;	#the predicted  residue structure comp.


  #print STDERR "ali_seq= $ali_seq\n";
  #print STDERR "aliSeq= $aliSeq\n";

  @align= split(//,$aliSeq);
  $aliLen=$#align + 2; 		# 1 for 0th element and 1 for the original residue.
    
  foreach $y (0..$#align) {
    $AA=$align[$y];
    $allResPro{$AA}+=(100/$aliLen);
    $bigPhdResPro{$phdStr.$AA}+=(100/$aliLen);

    if ($ind<=$par{"nterm"}) {
      $ntermResPro{$AA}+=(100/$aliLen);
    }

    if ($phdAcc=~ /Exp/) {	# the pred acc
      $expPhdResPro{$AA}+=(100/$aliLen);
    } 
     
  }

  $allResPro{$res}+= (100/$aliLen);

  $bigPhdResPro{$phdStr.$res}+=(100/$aliLen);
    
    
  if ($ind<=$par{"nterm"}) {
    $ntermResPro{$res}+=(100/$aliLen);
  }

  if ($phdAcc=~ /Exp/) {	# the pred acc state
    $expPhdResPro{$res}+=(100/$aliLen);
  } 


}

# now print out the results!
# first the single compostions!

foreach $fh ($fhSeq,$fhSeqPro,$fhPhdStr,$fhPhdBig,$fhPhdBigPro) {
  if (defined $locDb{$par{'protId'}}) {
    print $fh "$par{'protId'}\t$locDb{$par{'protId'}}\txx\t$resCnt";
  } else {
    print $fh "$par{'protId'}\txx\txx\t$resCnt";
  }
}
foreach $fh ($fhNterm,$fhNtermPro) {
  if (defined $locDb{$par{'protId'}}) {
    print $fh "$par{'protId'}\t$locDb{$par{'protId'}}\txx\t$ntermCnt";
  } else {
    print $fh "$par{'protId'}\txx\txx\t$ntermCnt";
  }
}

foreach $fh ($fhPhdExp,$fhPhdExpPro) {
  if (defined $locDb{$par{'protId'}}) {
    print $fh "$par{'protId'}\t$locDb{$par{'protId'}}\txx\t$expPhdCnt";
  } else {
    print $fh "$par{'protId'}\txx\txx\t$expPhdCnt";
  }
}
 

foreach $it ("V","L","I","M","F","W","Y","G","A","P","S","T","C","H","R","K","Q","E","N","D") {
  $allRes{$it}=round(100*$allRes{$it}/$resCnt);
  print $fhSeq "\t$allRes{$it}";
  $allResPro{$it}=round ($allResPro{$it}/$resCnt);
  print $fhSeqPro "\t$allResPro{$it}";
    
  $expPhdRes{$it}=round(100*$expPhdRes{$it}/$expPhdCnt);
  print $fhPhdExp "\t$expPhdRes{$it}";
    
  $expPhdResPro{$it}= round($expPhdResPro{$it}/$expPhdCnt);
  print $fhPhdExpPro "\t$expPhdResPro{$it}"; 

    
  $ntermRes{$it}= round(100*$ntermRes{$it}/$ntermCnt);
  print $fhNterm "\t$ntermRes{$it}";

  $ntermResPro{$it}= round($ntermResPro{$it}/$ntermCnt);
  print $fhNtermPro "\t$ntermResPro{$it}";

}

  
#now the structure comp
foreach $str (keys %secType) {

  $strPhdComp{$str}=round(100*$strPhdComp{$str}/$resCnt);
  print $fhPhdStr "\t$strPhdComp{$str}";
    
  
  foreach $it ("V","L","I","M","F","W","Y","G","A","P","S","T","C","H","R","K","Q","E","N","D") {
      
    if (defined $bigPhdRes{$str.$it}) {
	
      $bigPhdRes{$str.$it}=round(100*$bigPhdRes{$str.$it}/$resCnt);
      print $fhPhdBig "\t$bigPhdRes{$str.$it}";
    } else {
      print $fhPhdBig "\t0";
    }

    if (defined $bigPhdResPro{$str.$it}) {
      $bigPhdResPro{$str.$it}= round($bigPhdResPro{$str.$it}/$resCnt);
      print $fhPhdBigPro "\t$bigPhdResPro{$str.$it}";
    } else {
      print $fhPhdBigPro "\t0";
    }   

  }
}

foreach $fh ($fhSeq,$fhSeqPro,$fhPhdExp,$fhPhdExpPro,$fhNterm,$fhNtermPro,$fhPhdStr,$fhPhdBig,$fhPhdBigPro) {
  print $fh "\n";
}
print $fhData "$par{'protId'}\t$Seq\t$Sec\t$Acc\n";


system("rm $par{'compFileList'} $fileOutDat");
# ==================================================================================================


sub round {
    local($tmp)=@_;
    local($var)= $tmp * 1000;
    $dec=$var - int ($var);
    if ( $dec gt .5){
	$var = int ($var) + 1;
	$tmp = $var/1000;
	return ($tmp);
    }
    else{
       $tmp = int ($var) / 1000; 
	return ($tmp);
    }
}

#==============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    
#-------------------------------------------------------------------------------#   getDistanceNewCurveIde      out= pide value for new curve
#       in:                     $lali
#       out:                    $pide
#                               pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#------------------------------------------------------------------------------- 
   $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
        if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
    $loc= 510 * $laliLoc ** ($expon);
    $loc=100 if ($loc>100);     # saturation
    return($loc,"ok $sbrName");
}                               # end of getDistanceNewCurveIde




#------------------------------------------------------------------------------------------------------------------
