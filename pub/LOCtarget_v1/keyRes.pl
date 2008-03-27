#! /usr/bin/perl -w
## scr to format LOCkey genome prediction results for web display.

$fhin="FHIN";
$fhout="FHOUT";


$par{'minAcc'}=                  20;

if ($ARGV[0]=~/^(help|\?)/){
  print STDERR "Perl wrapper to generate statistics for keyword Testing\n";
  exit;
}

if(!defined $ARGV[0]){
  print STDERR "needed input rdb file(output of swissKwVec.pl) not provided\n";
  print  "needed input rdb file(output of swissKwVec.pl) not provided\n";
}
else{
  $par{"fileRdb"}=$ARGV[0];

}

#extract org id


$fileOutRdb= "keyRes.rdb";


open($fhout,">".$fileOutRdb)|| die "**could not open out file= $fileOutRdb\n";
print $fhout "#out gen by $0\n";
print $fhout "Sequence\tLOCkey prediction\tSWISS-PROT keywords\n";

open($fhin,$par{'fileRdb'}) || die "not open $par{'fileRdb'}\n";

while(<$fhin>){
  undef $accStack;
  undef $locStack;

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
    @tmp=split(/\t/,$_);
    $id=$tmp[0];
    @pred=sort {$tmp[$b]<=>$tmp[$a]}(4..$#tmp-1);
    $keyList= $tmp[$#tmp];
    chomp($keyList);
    if($tmp[$pred[0]]<$par{'minAcc'}){#no prediction
      next;
    }
 
 

    foreach $i (0..$#pred){
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
    print $fhout "$id\t$locStack\t$keyList\n";
    }
}

close $fhout;

$maxCol=0;  #start with col usage=0;
$cnt=0;

open($fhin,$fileOutRdb) || die "Could not open Cubic help archive!\n";
while(<$fhin>){
  next if /^\#/;
  chomp($_);
  @tmp=split(/\t/,$_);
  $data[$cnt]= [ @tmp ];
  $cnt++;
  $thisCol= $#tmp+1;
  if($thisCol>$maxCol){
    $maxCol=$thisCol;
    
  }
  if ($thisCol>2){
    print STDERR "$_";
    print  "$_";
  }
}

close $fhin;
exit;
print STDERR "max col detected= $maxCol\n";
open($fhout,">".$fileOutHtml) || die "could not open outfile= $fileOut\n";

&formatHtml;

exit;

#========================================================================
sub formatHtml {

  foreach $row (0..$#data){
    #now format the rows!
    print $fhout "$data[$row][0]";
    foreach $col (1..($maxCol-1)){
      print $fhout "$data[$row][$col]";
    }
    print $fhout "\n";
  }

}

