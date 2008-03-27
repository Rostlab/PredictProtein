#! /usr/bin/perl
## scr to assign localization by homology (AccVsHssp dis curve + blastProcess ouput needed)

$scr=$0;
$scr=~m /^(.*\/).*?/;
$par{"dirHome"}=       $1;
$par{"fileList"} =     $ARGV[0]; #list of proteins which are to be annotated.
$par{"fileLoc"}  =     $ARGV[1]; #list of proteins with known loci
$par{"filePairs"}=     $ARGV[2]; #hssp  pairs  output from blastProcess.
$par{"jobId"}    =     "";

foreach $data (@ARGV){

  if($data=~ /=/){
    @data=split(/=/,$data);
    $par{$data[0]}=$data[1];
  }
}


print "list of parameters input to $0\n";

foreach $data (keys %par){
  print "$data\t$par{$data}\n";

}



$par{'dirCurve'}=            $par{"dirHome"}."AveCurveLoci/";
$par{'filePre'}=             "accVsdis_";
$par{'locList'}=             "'cyt','ext','nuc','mit','pla','not'";
$par{'thresh'}=              5;

$fhout="FHOUT";
$fhNo="FHNO";
$fhin="FHIN";
$fhData= "FHDATA";
$fherr= "FHERR";

$fileOut="homAnno.rdb";
$fileOut.=$par{"jobId"}; #the output files
$fileErr="noPairs.err";
$fileErr.=$par{"jobId"};

open($fhin,$par{"fileList"}) || eval{print "could not open  $par{'fileList'}";exit;};
while(<$fhin>){
  next if /^\#/;
  @tmp=split(/[\s]+/,$_);
  $protList{$tmp[0]}=1;#the list of seq to be annotated
}

close $fhin;

open($fhin,$par{"fileLoc"})  || eval{print "could not open  $par{'fileLoc'}\n";exit;};
while(<$fhin>){
  next if /^\#/;
  @tmp=split(/[\s]+/,$_);
  $locDb{$tmp[0]}=$tmp[1]; #the annotated Db
}
close ($fhin);

#read the AccVsdis curves!

foreach $loc (eval $par{'locList'}){

  $fileCurve= $par{'dirCurve'}.$par{'filePre'}.$loc.".dat";
  open($fhin,$fileCurve) || eval{print "could not open  $fileCurve\n";exit;};
  while(<$fhin>){
    next if /^\#/;
    @tmp=split(/[\s]+/,$_);
    $curve{$loc}{$tmp[0]}=$tmp[1];
  }
  close $fhin;
}


open($fhout,">".$fileOut) || eval{print "could not open  $fileOut\n";exit;};
print $fhout "#out gen by $0\n";
print $fhout "#id\tlocPred\tacc\talterPred\n";

#now read Blast output

open($fhin,$par{"filePairs"}) || eval { print "could not open blast  file= $par{'filePairs'}\n";exit;};

while(<$fhin>){
  undef @locList;undef @accList;undef @homList; undef @sortAcc;
  undef $locList;undef $accList; undef $homList;
  next if (/^\#/ || /^id1/);
  $_=~s/\n//g;
  @tmp=split(/[\s\t]+/,$_);
  $id1=$tmp[0];  # first protein
  next if (!(defined $protList{$id1}));
  $found{$id1}=1; #this prot was in hssp pairs file!

  if (defined $locDb{$id1}){
    $loc= $locDb{$id1};
    print  $fhout "$id1\t$loc\t100\n"; #acc=100 since protein has annotated loci
    next;
  }

  @idList=split(/,/,$tmp[2]); @disList=split(/,/,$tmp[3]);
  if($#idList != $#disList){
    print STDERR "num prot= $#idList not equal to num pid's= $#disList for port= $id\n";
    print STDERR "check input file format!\n";
    exit;
  }

  foreach $j (0..$#disList){
    next if ($disList[$j]<$par{'thresh'}); #the min hssp dis to be considered

    if(defined $locDb{$idList[$j]}){
      $hom=$idList[$j];
      $oriLoc=$locDb{$hom};
      if($par{'locList'} !~ /$oriLoc/){
	$loc="not";
      }
      else{
	$loc=$oriLoc;
      }

      $dis=$disList[$j];
      next if (! defined $curve{$loc}{$dis});
      $acc= $curve{$loc}{$dis};
      push @locList,$oriLoc;
      push @homList,$hom;
      push @accList,$acc;
    }

  }

  #now process if any homologs discovered
  next if (! $locList[0]);

  @sortAcc= sort {$accList[$b] <=> $accList[$a]} (0..$#accList);

  $it=$sortAcc[0];
  $homLoc=$locList[$it];
  $homId= $homList[$it];
  $acc= $accList[$it];
  print $fhout "$id1\t$homLoc\t$acc\t$homId";

  if(! $sortAcc[1]){
    print $fhout "\n";
    next;
  }

  foreach $j (1..$#sortAcc){
    $it=$sortAcc[$j];
    if(! $locList){
      $locList=$locList[$it];
    }
    else{
      $locList.=",$locList[$it]";
    }
    if(! $homList){
      $homList=$homList[$it];
    }
    else{
      $homList.=",$homList[$it]";
    }
    if(! $accList){
      $accList=$accList[$it];
    }
    else{
      $accList.=",$accList[$it]";
      }
  }
  print $fhout "\t$locList\t$accList\t$homList\n";
}

close $fhout;

open($fherr,">".$fileErr) || die "could not open $fileErr\n";
print $fherr "#out gen by $0\n";

foreach $id (keys %protList){

  if(! defined $found{$id}){
    print $fherr "$id\n";
  }

}
close $fherr;
