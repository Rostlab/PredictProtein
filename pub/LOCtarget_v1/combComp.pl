#! /usr/bin/perl -w

##hack scr that combines a list of input compo files into one Compo file!!!!

$fhin="FHIN";
$fhout="FHOUT";

$fileOut= $ARGV[0];

if(-e $fileOut){
  print STDERR "fileOut=$fileOut already exists! moved to $fileOut-old\n";
  system("mv $fileOut $fileOut-old");
}

open($fhout, ">".$fileOut) || die "could not open =$fileOut\n";
print $fhout "#out gen by $0\n";
print $fhout "#out gen by combining files:";

foreach $i (1..$#ARGV){
  print $fhout "\t$ARGV[$i]";
}
print $fhout "\n";


foreach $j (1..$#ARGV){
  $fileIn=$ARGV[$j];

  $ind++;
  $cnt=0;
  open($fhin,$fileIn) || die "could not open= $fileIn\n";
  while(<$fhin>){
    if(/^\#pdb_id/){
      @tmp=split(/\s+/,$_);
      push @hdr,@tmp[4..$#tmp];
    }
    next if /^\#/;
    $cnt++;
    @tmp=split(/\s+/,$_);
    $data[$cnt][$ind]=$_;

  }
}

#now pr out hdr
print $fhout "#pdb_id\txx\txx\tlen";

foreach $x (0..$#hdr){
  print $fhout "\t$hdr[$x]";
}

print $fhout "\n";

foreach $i (1..$cnt){

  @comp = split(/\s+/,$data[$i][1]);
  $protId= $comp[0];
  print $fhout "$comp[0]";
  foreach $k (1..$#comp){
    print $fhout "\t$comp[$k]";
  }

  foreach $j (2..$ind){
    #print STDERR "$data[$i][$j]";
    @comp = split(/\s+/,$data[$i][$j]);
    $id=$comp[0];

    if($id ne $protId){
      print STDERR "id=$id not same as protId= $protId\n";
      exit;
    }

    foreach $k (4..$#comp){
      print $fhout "\t$comp[$k]";
    }

  }
  print $fhout "\n";

}
