#!/usr/local/bin/perl -w

#scr to predict sub loc

# inputs: 1) file with PDB struct

#read input
$scr=$0;
$scr=~m /^(.*\/).*?/;

$scr{"dirHome"}=                 $1;

#$scr{"pdb2fasta"}=               $scr{"dirHome"}."pdb2fasta.pl";
$scr{"locKey"}=                  $scr{"dirHome"}."swissKwVec.pl";
$scr{"predNLS"}=                 $scr{"dirHome"}."pp_resonline.pl";
$scr{"blastall"}=                "/usr/pub/molbio/blast/blastall";
$scr{"blastProc"}=               $scr{"dirHome"}."myBlastAllProcessRdb.pl";
$scr{"annoHom"}=                 $scr{"dirHome"}."annoHom.pl";
$scr{"procHom"}=                 $scr{"dirHome"}."proc_annoHom.pl";
$scr{"annoKey"}=                 $scr{"dirHome"}."swissKwVec.pl";
$scr{"keyPred"}=                 $scr{"dirHome"}."KwPred.pl";
$scr{"svmPred"}=                 $scr{"dirHome"}."svmPred.pl";

$db{"dbHome"}=                   $scr{"dirHome"}."db/";

$db{"annoProt"}=                 $db{"dbHome"}."InterpretEukaLoci.dat";

$par{"fileIn"}=                  "";# the fasta sequence input!
$par{"sendMail"}=                "LOCnet.out";
$par{"fileErr"}=                 "err.out";
$par{"dirOut"}=                  "./"; # the def out dir
$par{"jobId"}=                   "";
$par{"emailId"}=                 "none";
$par{"protId"}=                  "protId";
$par{"orgType"}=                 "Eukaryotic";
$par{"protList"}=                "protList";
$par{"nlsOut"}=                  "nlsOut";
$par{"nlsTrace"}=                "nlsTrace";
$par{"nlsSum"}=                  "nlsSum";
$par{"fileRun"}=                 "run.out";
$par{"blastAll"}=                "blastAll";
$par{"hsspPairs"}=               "pairs-hsspDis.rdb";
$par{"scaledPairs"}=             "pairs-scaleDis.rdb";
$par{"homAnno"}=                 "homAnno.rdb";
$par{"keyAnno"}=                 "protLoc.rdb";
$par{"keyErr"}=                  "protLoc.err";
$par{"keyList"}=                 "KeyList.rdb";
$par{"keyPred"}=                 "predList.rdb";
$par{"svm"}=                     "svm";


$trans{'ext'}="Extracellular";$trans{'cyt'}="Cytoplasmic";$trans{'nuc'}="Nuclear";$trans{'mit'}="Mitochondrial";
$trans{'pla'}="Chloroplast"; $trans{'ret'}="Endoplasmic-reticulum"; $trans{'gol'}="Golgi"; $trans{'oxi'}="Peroxysomal"; $trans{'lys'}="Lysosomal";$trans{'rip'}="Periplasmic";$trans{'vac'}="Vacuolar";


$fhErr="FHERR";
$fhin="FHIN";
$fhout="FHOUT";
$fhmail= "FHMAIL"; # mail file handle.



if ($#ARGV<0){
  print  "no fasta sequence file provided\n";
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

if($par{"fileIn"} !~ /\w/){ #the fata input file!

print  "no input file defined\n";
exit;
}

open($fhErr,">".$par{"fileErr"}) || die "could not open $par{'fileErr'}\n";
print $fhErr "out gen by $0\n";
print "xx\n";


open($fhin, $par{'fileIn'}) || die "could not open = $par{'fileIn'}\n";
while(<$fhin>){
  next if /^\#/;
  if(/^>/){
    m/^>(.*?)\s/;
    $par{'protId'}=$1;
    print $fhErr "$1\n";
  }

}

close $fhout;
close $fhin;




foreach $var (keys %par){

  if($var!~ /fileIn|job|dirOut|protId|orgType|email/){
    $par{$var}.= $par{"jobId"};
  }
  print $fhErr "$var=$par{$var}\n";
}



#checkpoint


#run predictNLS

system("$scr{'predNLS'} fileIn=$par{'fileIn'} dirOut=$par{'dirOut'} fileOut=$par{'nlsOut'} html=0 fileTrace=$par{'nlsTrace'} fileSummary=$par{'nlsSum'} >>$par{'fileRun'}");

#checkpoint

if(-e $par{"nlsSum"}){

  #summary file exists!
  undef $state;

  open($fhin,$par{"nlsSum"}) || die "could not open $par{'nlsSum'}\n";

  while(<$fhin>){
    s/\s+//g;
    $state=$_;
  }
  close $fhin;

  if($state==1){#nls exists!

    $metDb{'nls'}=100;
    push @{$resDb{'nls'}}, "Method: predictNLS\n";
    if($par{'orgType'}=~ /Euka/){
      push @{$resDb{'nls'}}, "Predicted localization: Nuclear\n";
    }
    else{
      push @{$resDb{'nls'}}, "Predicted localization: Cytoplasmic\n";
    }
    push @{$resDb{'nls'}}, "Confidence: 100\n";
    push @{$resDb{'nls'}}, "Details: \n";

    # read nlsOut file
    open($fhin,$par{"nlsOut"}) || eval {print "scr $0 could not open $par{'nlsOut'}\n"; 
					exit;};


    $rdInd=0; $mch=0;

    while(<$fhin>){

      if(/List of NLS/){
	$mch=1;
      }

      if($mch==1 && /-----------/){
	$rdInd++;
	push @{$resDb{'nls'}}, $_;
	last if ($rdInd==2);
      }

      if($rdInd==1){
	push @{$resDb{'nls'}}, $_;
      }

    }
    close $fhin;
  }

}

#now read fasta file & run BLAST

system("$scr{'blastall'} -p blastp -i $par{'fileIn'} -d /data/blast/swiss -b 1000 -e 100 -m 8 -o  $par{'blastAll'}");



system("$scr{'blastProc'} $par{'blastAll'} $par{'fileIn'} jobId=$par{'jobId'} >>$par{'fileRun'}");

#checkpoint


open($fhout, ">".$par{'protList'}) || die "could not open $par{'protList'}\n";
print $fhout "#out gen by $0\n";

if(-e $par{'hsspPairs'}){

  open($fhin,$par{'hsspPairs'}) || die "could not open $par{'hsspPairs'}\n";
  while(<$fhin>){
    next if /^(\#|id1)/;
    @tmp=split(/\s+/,$_);
    print $fhout "$tmp[0]\n";
  }
  close ($fhin);
}
close ($fhout);
#now pred with homology
#usage: annoHom.pl protList annoList hssp-pairs

system("$scr{'annoHom'} fileList=$par{'protList'} fileLoc=$db{'annoProt'} filePairs=$par{'hsspPairs'} dirHome=$scr{'dirHome'} jobId=$par{'jobId'} >>$par{'fileRun'}");



#process homology annotation

if (-e $par{"homAnno"}){

  # annotation by homology possible

  open($fhin, $par{"homAnno"}) || eval { print "scr $0 could not open $par{'homAnno'}\n";exit;};

  $rdInd=0;
  while(<$fhin>){
    next if /^\#/;
    @tmp=split(/\s+/,$_);
    $loc=$trans{$tmp[1]};
    $conf=$tmp[2];
    $hom=$tmp[3];
    $rdInd++;
    if($rdInd==1 && $conf>35){
      $metDb{'hom'}=$conf;
    }
    if($tmp[0]=~ /_(\w)/){#chains
      push @chDb, $1;
      push @{$resDb{'hom'}{$1}},"Method: Homology\n";
      push @{$resDb{'hom'}{$1}},"Predicted localization: $loc\n";
      push @{$resDb{'hom'}{$1}},"Confidence: $conf\n";
      push @{$resDb{'hom'}{$1}},"Details: $hom\n";
    }
    else{# no chains
      if($par{'orgType'}=~ /Proka/i){
	if($loc=~ /nuc|mit|pla/i){
	  $loc="Cytoplasmic";
	}
	if($loc=~ /gol|ret|lys|oxi/i){
	  $loc="Extracellular";
	}

      }

      push @{$resDb{'hom'}},"Method: Homology\n";
      push @{$resDb{'hom'}},"Predicted localization: $loc\n";
      push @{$resDb{'hom'}},"Confidence: $conf\n";
      push @{$resDb{'hom'}},"Details: $hom\n";
      
    }

  }
  close $fhin;
}


#now pred with keywords 
system("$scr{'annoKey'} $par{'protList'} fileHom=$par{'hsspPairs'} dirDb=$db{'dbHome'} jobId=$par{'jobId'}>>$par{'fileRun'}");

system("$scr{'keyPred'} $par{'keyAnno'} $par{'jobId'} >>$par{'fileRun'}");

if (-e $par{"keyPred"}){

  # annotation by homology possible

  open($fhin, $par{"keyPred"}) || eval { print "scr $0 could not open $par{'keyPred'}\n";  
					 exit;};

  $rdInd=0;

  while(<$fhin>){
    next if /^\#/;
    @tmp=split(/\s+/,$_);
    $loc=$tmp[1];
    $conf=$tmp[2];
    $keys=$tmp[3];
    $rdInd++;
    if($rdInd==1 && $conf>35){
      $metDb{'key'}=$conf;
    }
    if($tmp[0]=~ /_(\w)/){#chains

      push @{$resDb{'key'}{$1}},"Method: LOCkey (SWISS-PROT keywords based prediction)\n";
      push @{$resDb{'key'}{$1}},"Predicted localization: $loc\n";
      push @{$resDb{'key'}{$1}},"Confidence: $conf\n";
      push @{$resDb{'key'}{$1}},"Details: $keys\n";
    }
    else{# no chains
      if($par{'orgType'}=~ /Proka/i){
	if($loc=~ /nuc|mit|pla/i){
	  $loc="Cytoplasmic";
	}
	if($loc=~ /gol|ret|lys|oxi/){
	  $loc="Extracellular";
	}

      }
      push @{$resDb{'key'}},"Method:LOCkey (SWISS-PROT keywords based prediction)\n";
      push @{$resDb{'key'}},"Predicted localization: $loc\n";
      push @{$resDb{'key'}},"Confidence: $conf\n";
      push @{$resDb{'key'}},"Details: $keys\n";

    }

  }
  close $fhin;
}


#pred with svm
system("$scr{'svmPred'} $par{'fileIn'} $par{'jobId'} >>$par{'fileRun'}");

if (-e $par{"svm"}){# results from SVM

    open($fhin, $par{"svm"}) || eval { print "scr $0 could not open $par{'svm'}\n";
				       exit;};

    $minConf=65;

    while(<$fhin>){
      next if /^\#/;
      @tmp=split(/\s+/,$_);
      $loc=$trans{$tmp[1]};
      $conf=$tmp[2];

      $metDb{'svm'}=$minConf;
      if($tmp[0]=~/_(\w)/){#chains
      
	push @{$resDb{'svm'}{$1}},"Method: Neural Network\n";
	push @{$resDb{'svm'}{$1}},"Predicted localization:YYYYY\n";
	push @{$resDb{'svm'}{$1}},"Confidence: $minConf\n";

      }
      else{# no chains
	if($par{'orgType'}=~ /Proka/i){
	  if($loc=~ /nuc|mit|pla/i){
	    $loc="Cytoplasmic";
	  }
	  if($loc=~ /gol|ret|lys|oxi/i){
	    $loc="Extracellular";
	  }
	  
	}
	push @{$resDb{'svm'}},"Method: Neural Network\n";
	push @{$resDb{'svm'}},"Predicted localization: $loc\n";
	push @{$resDb{'svm'}},"Confidence: $minConf\n";
      }

    }
    close $fhin;
}



#now print out the final results
open($fhmail,">".$par{"sendMail"}) || eval {print "scr $0 could not open $par{'sendMail'}\n. No email file being generated; contact admin.\n";exit;};

print  $fhmail "Results from LOCtarget\n\n";
print  $fhmail "The first method is the most accurate localization prediction\n";
print  $fhmail "Localization prediction for: $par{'protId'}\n\n\n";
print  $fhmail "Organism type: $par{'orgType'}\n\n\n";

if(defined $metDb{'nls'}){

  if($par{'orgType'}=~ /Euka/i){
    foreach $data (@{$resDb{'nls'}}){
      print $fhmail "$data";
    }
    print $fhmail "\n\n";
  }
  print $fhmail "Predicted Localization: Cytoplasmic\n";
  print $fhmail "Confidence: 100\n\n";
}

@sortMet = sort {$metDb{$b} <=> $metDb{$a} } (keys %metDb);

foreach $met (@sortMet){

  next if ($met eq "nls");

  if(defined $chDb[0]){#submitted protein has chains!!

    foreach $ch (@chDb){
      print $fhmail "Results for chain: $ch\n";
      foreach $data (@{$resDb{$met}{$ch}}){
	print $fhmail "$data";
      }
      print $fhmail "\n\n";
    }
  }
  else{
    foreach $data (@{$resDb{$met}}){
      print $fhmail "$data";
    }
    print $fhmail "\n\n";
  }
}


$send= `cat $par{'sendMail'}`;

open(FHTEMP, ">>".$par{'fileRun'}) || die "could not open $par{'fileRun'}\n";

print FHTEMP "$send\n";

close (FHTEMP);


foreach $val (keys %par){

  next if($val eq "fileIn" || $val eq "sendMail" || $val eq "dirOut" || $val eq "jobId" || $val eq "emailId" || $val eq "orgType" || $val eq "fileRun");

  if(-e $par{$val}){
    system("rm $par{$val}");
  }
}

system("rm pairs* TSTi* tst-*");

