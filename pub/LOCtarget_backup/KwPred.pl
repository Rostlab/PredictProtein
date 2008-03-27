#! /usr/bin/perl -w
##perl wrapper to order keywords prediction by confidence ..input is protLoc.rdb

if ($ARGV[0]=~/^(h|\?)/){
  print STDERR "Perl wrapper to generate statistics for keyword Testing\n";
  exit;
}



print "#running scr $0\n";


$par{'predOut'}=                        "predList.rdb"; # the predictions in human readable form and ordered by confidence

$par{'minAcc'}=                         15;# the min accuracy
$par{'minEnt'}=                         70;#the min normalized fractional entropy.
$par{'maxEnt'}=                         99;# the max normalized fractional entropy.
$par{'jobId'}=                          "";


$trans{'ext'}="Extracellular";$trans{'cyt'}="Cytoplasmic";$trans{'nuc'}="Nuclear";$trans{'mit'}="Mitochondrial";
$trans{'pla'}="Chloroplast"; $trans{'ret'}="Endoplasmic-reticulum"; $trans{'gol'}="Golgi"; $trans{'oxi'}="Peroxysomal"; $trans{'lys'}="Lysosomal";$trans{'rip'}="Periplasmic";$trans{'vac'}="Vacuolar";

if(!defined $ARGV[0]){
  print STDERR "needed input rdb file(output of swissKwVec.pl.. protLoc.rdb) not provided\n";
}
else{
  $par{"fileRdb"}=$ARGV[0];

}

$par{'jobId'}= $ARGV[1];

$par{'predOut'}.=$par{'jobId'};

open($fhPred,">".$par{'predOut'}) || die "**could not open out file =$par{'predOut'}\n";
print $fhPred "#out gen by $0\n";
print $fhPred "#id\tloc\tconf\tkeywords\talterPred\tprob\n";

open($fhin,$par{'fileRdb'}) || eval{print "could not open in file= $par{'fileRdb'}\n";exit;};

$lnCnt=0;
while(<$fhin>){
  undef $locStack;
  undef $accStack;
  $lnCnt++;
  if(/^\#/ && $lnCnt <7){
    if(/^\#proteinId/){
      @tmp=split(/[\s]+/,$_);
      foreach $i (4..$#tmp){
	$ind{$i}=$tmp[$i];
      }
      #print STDERR "$_";
    }
  }
  elsif(/^\#/){
    next;
  }
  else{
    chomp;
    @tmp=split(/\t/,$_);
    $id=$tmp[0];
    $data{$id}{'ent'}=$tmp[1];
    @pred=sort {$tmp[$b]<=>$tmp[$a]}(4..$#tmp-1);
    $data{$id}{'predLoc'}=$ind{$pred[0]};
    #print STDERR "$id\t$ind{$pred[0]}\n";
    $data{$id}{'predProb'}=$pred[0];
    $data{$id}{'keys'}=$tmp[$#tmp];
    foreach $i (1..$#pred){
      $tr=$pred[$i];
      if($tmp[$tr]>$par{'minAcc'}){#included in stack
	if(!defined $accStack){
	  $locStack="$ind{$tr}";
	  $accStack="$tmp[$tr]";
	}
	else{
	  $locStack.=",$ind{$tr}";
	  $accStack.=",$tmp[$tr]";
	}
      }
    }
    $data{$id}{'locStack'}=$locStack;
    $data{$id}{'accStack'}=$accStack;
    
  }
}

close $fhin;

@idList= keys %data;
#print STDERR "@idList\n";
#exit;
@idList= sort {$data{$b}{'ent'}<=>$data{$a}{'ent'} or $data{$b}{'predProb'}<=> $data{$a}{'predProb'}} (keys %data);

foreach $id (@idList){
  $predLoc= $trans{$data{$id}{'predLoc'}};

  print $fhPred "$id\t$predLoc\t$data{$id}{'ent'}\t$data{$id}{'keys'}";
  if(defined $data{$id}{'locStack'}){
    print $fhPred "\t$data{$id}{'locStack'}\t$data{$id}{'accStack'}";
    print  "\t$data{$id}{'locStack'}\t$data{$id}{'accStack'}\n";
    
  }

  print $fhPred "\n";

}

close $fhPred;

