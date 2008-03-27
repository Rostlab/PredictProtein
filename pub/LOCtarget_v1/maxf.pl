#! /usr/bin/perl


$scr=$0;
$scr=~m /^(.*\/).*?/;

$scr{"dirHome"}=                 $1;

$par{'maxHom'}= "/usr/pub/molbio/maxhom/scr/maxhom.pl";
$par{'hsspFilter'}="/usr/pub/molbio/perl/hssp_filter.pl";
$par{'prof'}="/usr/pub/molbio/prof/prof";
$par{'protId'}=  "protId";
$par{'fileFasta'}= "protId.f";
$par{'fileHssp'}= "protId.hssp";
$par{'fileProf'}= "protId.rdbProf";

#now read inputs!
print STDERR "runing scr =$0\n";

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
    print STDERR "arg= $tmp[0]\tval=$tmp[1]\n";
  }

}

$fhErr="FHERR";
$fileErr= "maxf.err";

open($fhErr,">".$fileErr) || die "could not open $fileErr\n";
print $fhErr "#out gen by $fileErr\n";

$id=$par{"protId"};

if(!(-e $par{"fileProf"})){
      
  if(!(-e $par{"fileHssp"})){

    system("$par{'maxHom'} $par{'fileFasta'}");

  }


  if(!(-e "$id.hssp")){
    print $fhErr "$id\tMaxhom failed\n";
    print "$id\tMaxhom failed\n";
  }
  
  system("$par{'hsspFilter'} $id.hssp thresh=10 threshSgi=10 mode=ide red=80");

  if(-e "$id-fil.hssp"){

    system(" mv $id-fil.hssp $par{'fileHssp'}");
  }
  else{
    print $fhErr "$id\tMaxFilter failed\n";
    print  "$id\tMaxFilter failed\n";
  }

	
  system("$par{'prof'} $par{'fileHssp'} both fileRdb=$par{'fileProf'}");
  if(!(-e $par{'fileProf'})){
    print $fhErr "$id\tProf failed\n";
    print  "$id\tProf failed\n";
  }
  

}

