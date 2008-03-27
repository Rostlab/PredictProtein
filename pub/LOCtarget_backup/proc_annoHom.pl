#! /usr/bin/perl 
## scr to assign loci based on confidence when predictions available from multiple methods.
## generates database for easy grep ..not in human readable format!

$par{'locList'}=             "'cyt','ext','nuc','mit','not'";

$trans{'ext'}="Extracellular";$trans{'cyt'}="Cytoplasmic";$trans{'nuc'}="Nuclear";$trans{'mit'}="Mitochondrial";
$trans{'pla'}="Chloroplast"; $trans{'ret'}="Endoplasmic-reticulum"; $trans{'gol'}="Golgi"; $trans{'oxi'}="Peroxysomal"; $trans{'lys'}="Lysosomal";$trans{'rip'}="Periplasmic";$trans{'vac'}="Vacuolar";


$fileList=$ARGV[0]; #the input file


$fhout="FHOUT";
$fhoutStat= "FHOUTSTAT";

$fileOut= "wwwPredLoc.dat";



open($fhout,">$fileOut") || die "could not open $fileOut\n";
print $fhout "#out gen by $0\n";
print $fhout "#prot\tmethod\tloci\tconf\tdetails\n";

$fileMet= $fileList;
print STDERR "proc= $fileMet\n";
open($fhin,$fileMet) || die "could not open $fileMet\n";
while(<$fhin>){
  next if /^\#/;
  @tmp=split(/[\s]+/,$_);
  $id=$tmp[0];
  if(defined $trans{$tmp[1]}){
    $loc=$trans{$tmp[1]};
  }
  else{
    $loc=$tmp[1];
  }
  $conf=$tmp[2];
  if(defined $tmp[3]){
    $exp=$tmp[3];
  }
  else{
    $exp="Experimental Annotation";
  }

  print $fhout "$id\t$loc\t$conf\t$exp\n";
  #print STDERR "$id\t$loc\t$conf\t$exp\n";

}
close($fhin);



close $fhout;
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
