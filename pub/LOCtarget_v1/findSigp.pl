#! /usr/bin/perl -w
# scr to process signalP output!
# scan though signalP out files, find the secreted proteins 
#--------criteria for secreted prot : mean S score >0.5

$fhin= "FHIN";
$fhdata= "FHDATA";
$fhErr= "FHERR";
$fhout= "FHOUT";
$fhout1= "FHOUT1";

$scr= $0;
$tag= int( rand 10000);
$scr{"signalP"} = "/usr/pub/molbio/signalp/signalp";

$par{"jobId"}=$tag;

$par{"protId"}= "protId";
$par{"fileFasta"}="protId.fasta";
$par{"fileOutSig"}="protId.sig";
$par{"fileSigRun"}="protId.sigOut";
$par{"orgType"}="Eukaryotic";
$par{"meanS"}{'euka'}= 0.50; # default value above which prot considered to be signalPeptides
$par{"meanS"}{'proka'}= 0.54; # default value above which prot considered to be signalPeptides




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

$par{"fileSigRun"}="$par{'protId'}.sigOut".$par{'jobId'};

if(-e $par{'fileFasta'}){#run SignalP

  if($par{'orgType'}=~ /Euka/i){
    system("$scr{'signalP'} -t euk $par{'fileFasta'} >$par{'fileSigRun'}");
  }
  else{
    system("$scr{'signalP'} -t gram- $par{'fileFasta'} >$par{'fileSigRun'}");
  }

}


if(!(-e $par{'fileSigRun'})){
  print "error running SignalP\n";
  exit;
}

open($fhout,">".$par{'fileOutSig'}) || die "could not open $par{'fileOutSig'}\n";

print $fhout "#SignalP predictions follow (service provided by http://www.cbs.dtu.dk/services/SignalP/):\n";


#now process $par{'fileSigRun'}
open($fhin,$par{'fileSigRun'}) || die "could not open $par{'fileSigRun'}\n";
while(<$fhin>){

  #print "ha\n";
  if(/^Prediction\:/){
    print $fhout "$_\n";
  }

}

print $fhout "for more information on SignalP see: http://www.cbs.dtu.dk/services/SignalP/\nPlease run your sequence on SignalP WWW server for latest version of the server\n";

close ($fhout);

system("rm $par{'fileSigRun'}");
