#! /usr/bin/perl -w

## scr to generate pairs for rdbBlast output from blastall change col no on line 132 as needed! 

if($#ARGV < 0){
  print "usage: scr allLoci.rdbBlast (the rdbBlast output from ~rost/perl/molbio/blastRun.pl)\n";
  exit;
}

$scr=$0;
$scr=~m /^(.*\/).*?/;

$par{'dirHome'}    =$1;
$par{'dirDb'}      =$par{'dirHome'}."db/";
$par{"minLali"}= 12; # minimal alignment length to consider hit
$par{"minDist"}= -10; # minimal distance from HSSP(new) curve (-3 -> at least 27%)
$par{"modeFilter"}= "new"; # filter according to old or new ide
$par{"modePDB"}= 0; # if processing pdb files
$par{"factor"}=0.26;# factor at which LALI scaled!
$par{"saturate"}=80 ;

$fileIn= $ARGV[0];

if(defined $ARGV[1]){
  $fileFasta= $ARGV[1];
}

if($ARGV[2]=~ /=(.*)/){
  $jobId=$1;
}
else{
  $jobId="";
}

print "scr =$0\n$ARGV[2]\tjobId=$jobId\n";
print STDERR "scr =$0\njobId=$jobId\n";
#if($curDir=~ /PDB/){
#  print STDERR "-------Proccessing PDB proteins!------------\n";
#  print STDERR "chains for aligned proteins will be dropped. For example 1sfg_G changed to 1sgf.\nDone since my current PDB prot db does not consider chains.\n Change mode in script to undo this effect\n";
#  $par{"modePDB"}=1;# change this back to 2 to process PDB proteins with chains!
#}


$fhin="FHIN";
$fhdata="FHDATA";

$fhout= "FHOUT";
$fout= "FOUT";
$fout1= "FOUT1";
$fout2= "FOUT2";
$fout3="FOUT3";
$fout4="FOUT4";

$fileOut= "pairs.rdb".$jobId;
$fileOutPid= "pairs-pid.rdb".$jobId;
$fileOutScaleDis="pairs-scaleDis.rdb".$jobId;
$fileOutExpect= "pairs-expect.rdb".$jobId;
$fileOutHssp= "pairs-hsspDis.rdb".$jobId;


open($fhout,">$fileOut")||  die "**could not open out file= $fileOut\n";

open($fout,">".$fileOutPid)||  die"**could not open out file= $fileOutPid\n";
open($fout1,">".$fileOutScaleDis)||  die"**could not open out file= $fileOutScaleDis\n";
open($fout2,">".$fileOutExpect)||  die"**could not open out file= $fileOutExpect\n";
open($fout3,">".$fileOutHssp)||  die"**could not open out file= $fileOutHssp\n";

foreach $fh ($fhout,$fout,$fout1,$fout2,$fout3){

print $fh "# Perl-RDB  blastProcessRdb format\n";
print $fh "# Output generated by $scr\n";

print $fh "# --------------------------------------------------------------------------------\n";


print $fh "# FORM  beg          blastProcessRdb \n";


print $fh "# FORM  general:     - lines starting with hashes contain comments or PARAMETERS\n";

print $fh "# FORM  general:     - columns are delimited by tabs\n";

print $fh "# FORM  format:      '# FORM  SPACE keyword SPACE further-information'\n";
print $fh "# FORM  parameters:  '# PARA: SPACE keyword SPACE=TAB value TAB (further-info)'\n";
print $fh "# FORM  notation:    '# NOTA: SPACE keyword SPACE=TAB explanation'\n";
print $fh "# FORM  1st row:     column names  (tab delimited)\n";
print $fh "# FORM  2nd row (may be): column format (tab delimited)\n";
print $fh "# FORM  rows 2|3-N:  column data   (tab delimited)\n";

print $fh "# FORM  end          blastProcessRdb\n";

print $fh "# --------------------------------------------------------------------------------\n";

print $fh "# NOTA  begin        blastProcessRdb ABBREVIATIONS\n";

print $fh "# NOTA               column names\n";

print $fh "# NOTA: id1          =    first identifier\n";


print $fh "# NOTA: len          =    length of id1\n";

print $fh "# NOTA: id2          =    second identifier     (list separated by ',')\n";


print $fh "# NOTA               parameters\n";


print $fh "# --------------------------------------------------------------------------------\n";


print $fh "# PARA  beg          \n",
        "# PARA: minLali      =    $par{'minLali'}\n",
        "# PARA: minDist      =    $par{'minDist'}\n",
        "# PARA  end          \n",
        "# --------------------------------------------------------------------------------\n";
}

print $fhout "id1\tlen\tid2\tdist\n";
print $fout "id1\tlen\tid2\tpid\n";
print $fout1 "id1\tlen\tid2\thsspScaleDis\n";
print $fout2 "id1\tlen\tid2\tblastProb(10*log E)\n";
print $fout3 "id1\tlen\tid2\thsspDis\n";


($HsspDb,$HsspCurve)=
  &rdHsspDb; #the Hssp Database

#foreach $key (keys %{$HsspCurve}){
#  print STDERR "lali= $key\tpid= $$HsspCurve{$key}\n";
  
#}

if($fileIn=~ /gz/){#zipped file
  open($fhin,"gunzip -c $fileIn|") || die "could not open input file= $fileIn\n";
}
else{
  open($fhin,$fileIn) ||  die "could not open input file= $fileIn\n";
}

undef %protList; # hash with list of proteins
undef %protLen;
#$id1=0; $id2=1; $pide=3; $lali=2; $dist=4; $prob=5; $score=6;
$id1=0; $id2=1; $pide=2; $lali=3; $dist=4; $prob=5; $score=6;

RDB:
while(<$fhin>){
  next if /^\#|id1/;
 
  @tmp=split(/[\s]+/,$_);
#  $query=$tmp[$id1];
  if($tmp[$id1]=~ /\|/){
    $tmp[$id1]=~m /\|(\w+)$/;
    $query=$1;
    #$query=~tr /[A-Z]/[a-z]/;
  }
  else{
    $query=$tmp[$id1];
    $query=~tr /[A-Z]/[a-z]/;
  }
  if($tmp[$id2]=~ /\|/){
    $tmp[$id2]=~m /\|(\w+)$/;
    $aliSeq= $1;
    if($par{"modePDB"}==1){
      if($aliSeq=~ /_\w$/){
	$aliSeq=~s /_\w//;
	#      print STDERR "$aliSeq\n";
      }
    }
  }
  else{
    #print STDERR "right place!\ttmp[id2]= $tmp[$id2]\n";
    $tmp[$id2]=~m /(\w+)/;
    $aliSeq=$1;
  }

  #$aliSeq= $1;
  if ($aliSeq !~ /\w/){
    print "aliseq= $aliSeq\n";
    exit;
  }


  if($aliSeq=~ /\w{2,}_\w{2,}/){
    $aliSeq=~tr /[A-Z]/[a-z]/;
  }
  
  $aliLen= $tmp[$lali];
  $pid= round ($tmp[$pide]); # percentage alignment identity
  #$hsspDis= round ($tmp[$dist]); #distance from HSSP curve as calculated by blastRun.pl
  $blastScore= round( $tmp[$score]); # the blast score
  $blastExpect= (10*$tmp[$prob])/10;# the blast E-val
  #$blastExpect= round($tmp[$prob]);
  if($blastExpect>0){
    $blastProb= round (10*log ($blastExpect));
   
  }
  else{
    $blastProb= -10000; 
  }
  
#filter; as in rost blastProcess.pl
  next RDB if ($aliLen < $par{"minLali"} );

  ($pideCurve,$msg)=
    &getDistanceNewCurveIde($aliLen);
  
  next RDB if ($msg !~ /^ok/);
 

  $disNewcurve= $tmp[$pide] - $pideCurve;
  $disNewcurve= round ( $disNewcurve);
  
  next RDB if ($disNewcurve < $par{"minDist"});
  $hsspDis= round ($disNewcurve);

  if($disNewcurve>0){
    $scaleDisCurve= round($disNewcurve*100/(100-$pideCurve));
  }
  else{
    $scaleDisCurve= $disNewcurve;
  }
    

  #print STDERR "$query\t$aliLen\t$aliSeq\t$hsspDis\n";

  if(!(defined $protList{$query})){
    # first time this protein is encountered.
    # print out info on last protein  and calculate length of this one
    if ($protList{$preQuery}== 1){
      print $fhout "$preQuery\t$protLen{$preQuery}\t$aliStack\t$distStack\n";
      print $fout "$preQuery\t$protLen{$preQuery}\t$aliStack\t$pidStack\n";
      print $fout1 "$preQuery\t$protLen{$preQuery}\t$aliStack\t$scaleDisStack\n";
      print $fout2 "$preQuery\t$protLen{$preQuery}\t$aliStack\t$expectStack\n";
      print $fout3 "$preQuery\t$protLen{$preQuery}\t$aliStack\t$hsspDisStack\n";

  }
    # undefine and reinitialize vars for new set
    undef $preQuery; undef $aliStack; undef $distStack;undef $pidStack; undef $scaleDisStack;undef $expectStack;undef $hsspDisStack;
    
    #--------------------------------------------------
    $preQuery= $query;
    $protList{$preQuery}=1;
    if($query eq $aliSeq){
      # aligned to same prot. length equals lali
      $protLen{$query}= $aliLen;
 
    }
    else{
      print STDERR "prot not ali to iself: $_";
      $dataIn= $fileFasta;

      if(-e $dataIn){
	open($fhdata, $dataIn) || print STDERR "data file= $dataIn not readable\n";
	undef $seq;
	while(<$fhdata>){
	  next if /^>/;
	  $_=~s /\s//g;
	  $seq.=$_;
	}
	
	$protLen{$query}= length $seq;
      }
      else {
	print STDERR "data file= $dataIn not found. Seq len cannot be calculated\n";
	#$protList{$preQuery}=2;
	$protLen{$query}=$aliLen;
      }

      $aliStack= $aliSeq; # added to stack only if frst alignment is to some other protein. Self ali not added to stack!
      $distStack= $disNewcurve; 
      $pidStack= $pid;
      $scaleDisStack= $scaleDisCurve;
      $expectStack= $blastProb;
      #$expectStack= $blastExpect;
      $hsspDisStack= $hsspDis;

      
      
    }# matches else for   if($query eq $aliSeq)

    
  }# matches if(!(defined $protList{$query}))
  elsif($protList{$query}==2){ # matches when len of protein not defined ..changed!
    next RDB;
  }
  else{
    if(defined $aliStack){
      $aliStack.= ",$aliSeq";
      $distStack.= ",$disNewcurve";
      $pidStack.=",$pid";
      $scaleDisStack.= ",$scaleDisCurve";
      $expectStack.=",$blastProb";
      #$expectStack.=",$blastExpect";
      $hsspDisStack.=",$hsspDis";

      
    }
    else{
      $distStack= $disNewcurve; 
      $pidStack= $pid;
      $scaleDisStack= $scaleDisCurve;
      $aliStack= $aliSeq;
      $expectStack=$blastProb;
      #$expectStack=$blastExpect;
      $hsspDisStack=$hsspDis;

    }
  }

}
  if ($protList{$preQuery}== 1){
    print $fhout "$preQuery\t$protLen{$preQuery}\t$aliStack\t$distStack\n";
    print $fout "$preQuery\t$protLen{$preQuery}\t$aliStack\t$pidStack\n";
    print $fout1 "$preQuery\t$protLen{$preQuery}\t$aliStack\t$scaleDisStack\n";
    print $fout2 "$preQuery\t$protLen{$preQuery}\t$aliStack\t$expectStack\n";
    print $fout3 "$preQuery\t$protLen{$preQuery}\t$aliStack\t$hsspDisStack\n";

  }

#------------------------------------------------------------------------------------------------------------------

sub round {
    local($tmp)=@_; 
    local($var)= $tmp;        
    $dec=$var - int ($var);
    if ( (abs  $dec) > .5){
      if($var > 0){
	$var = int ($var) + 1;
      }
      else{
	$var = int ($var) - 1;
      } 
	$tmp = $var;
	return ($tmp);
    }
    else{
       $tmp = int ($var); 
	return ($tmp);
   }
}


#==============================================================================
sub getDistanceNewCurveIde {
    local($laliLoc)=@_; local($expon,$loc);
    
#-------------------------------------------------------------------------------
#   getDistanceNewCurveIde      out= pide value for new curve
#       in:                     $lali
#       out:                    $pide
#                               pide= 510 * L ^ { -0.32 (1 + e ^-(L/1000)) }
#-------------------------------------------------------------------------------
    $sbrName="lib-br:getDistanceNewCurveIde";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! defined $laliLoc);
    return(0,"*** ERROR $sbrName: '$laliLoc' = alignment length??\n") 
	if (length($laliLoc)<1 || $laliLoc=~/[^0-9.]/);

    $expon= - 0.32 * ( 1 + exp (-$laliLoc/1000) );
    $loc= 510 * $laliLoc ** ($expon);
    $loc=100 if ($loc>100);     # saturation
    return($loc,"ok $sbrName");
}				# end of getDistanceNewCurveIde



#------------------------------------------------------------------------------------------------------------------

sub chDimLali {
  local ($lali)= @_; local($dimLali);
#-------------------------------------------------------------------------------
# chDimLali         dimension of length of alignment (LALI) is changed to that of pid
#conv formula       dimLali= LALI *$par{"factor"} with 200 being chosen somewhat arbitrarily.


  $dimLali= $lali * $par{"factor"} ;
  return($dimLali);
}

#------------------------------------------------------------------------------------------------------------------
sub rdHsspDb {
#-------------------------------------------------------------------------------
# rdHsspDb       read the precompiled Hssp Database
# 
  local(@hsspDb,%curveDb,$cnt,$fhin,$fileIn,@tmp);
  
  $fhin="SFHIN";
  $fileIn= $par{"dirDb"}."HsspCurve.rdb";
  $fileIn.="_".$par{"factor"};
  
  $cnt=0;
  if(!(-r $fileIn) ){
    print STDERR " dbFile= $fileIn not readable\n";
    exit;
    
  }
  open($fhin,$fileIn) || die "could not open dbFile = $fileIn\n";
  while(<$fhin>){
    next if /^\#/;
    @tmp=split(/[\s]+/,$_);
    $cnt++;
    @{$hsspDb[$cnt]}= @tmp;
       
    if($tmp[0] == int $tmp[0]){
      #put in hash
      
      $curveDb{$tmp[0]}=$tmp[2];
      
    }
 }   
  return(\@hsspDb,\%curveDb);
   
}


sub getPerpDistNewCurve {
  local($lali,$dimLali,$pid,$hsspDb,$hsspCurve)=@_;local($perpDist,@tmp,$cnt,$ind,$dist,$slope,@perpData,$sbrName,$sgnFlag,$pidCurve);
  
#-------------------------------------------------------------------------------
# requires two GLOBAL vars ($hsspDb is ref to global ARRAY and $hsspCurve is ref to global HASH)
#   getPerpDistNewCurve           gets perpendicular distance to HSSP curve in 'artificial' units of pid
#   in:                           requires HSSP curve database(/home/nair/perl/col/prot/HsspCurve.rdb
#   in:                           lali (in dimesions of pid : use chDimLali), pid
#  out:                           perpendicular distance to curve
#--------------------------------------------------------------------------------
  $sbrName="lib-br: getPerpDistNewCurve ";
    return(0,"*** ERROR $sbrName: lali not defined \n") if (! (defined $lali && defined $dimLali && defined $pid && defined $hsspDb && defined $hsspCurve));
# read HsspCurve db
    
  $satPidDist=$$hsspDb[$#{$hsspDb}][2];
  #print STDERR "saturation pid=$satPidDist\n";
  
  $minDist=100;
  $minDerDist=1;
  $sgnFlag=1;
  
  $pidCurve= $$hsspCurve{$lali};
  $tmpData=$pid - $pidCurve;
  
  #print STDERR "lali=$lali\tpidCurve= $pidCurve\n";
  
  if($pid < $pidCurve){
    $sgnFlag=-1;
    
  }
  
  if($dimLali>$par{'saturate'} || $sgnFlag==-1){
    $perpDist=$pid - $pidCurve;
    @perpData= ($dimLali,$satPidDist,0,$perpDist);
    
  }
  else{
    
    foreach $ind (1..$#{$hsspDb}){
      $curLali=$$hsspDb[$ind][1];
      $curPid=$$hsspDb[$ind][2];
      $curDer=$$hsspDb[$ind][3];
      $dist= sqrt(($dimLali-$curLali)**2 + ($pid-$curPid)**2);
      if($curDer!=0){
	if(($dimLali-$curLali)!=0){
	  $slope= ($pid-$curPid)/($dimLali-$curLali);
	  
	}
	else{
	  $slope=100;
	  
	}
	$prod= $curDer * $slope;
	$derDist= $prod + 1;
	if(abs($derDist) < abs($minDerDist)){
	  $minDerDist=$derDist;
	  @perpData= ($curLali,$curPid,$curDer,$dist);
	  #$dist= round $dist;
#	  print STDERR "data=$lali,$pid,$curDer,$dist\n";
	  
	}
	if($dist<$minDist){
	  $minDist=$dist;
	}
      }
      else{
	if ($dist <$minDist){
	  $minDist=$dist;
	  $dist=round $dist;
#	  print STDERR "$lali\t$pid\t$dist\n";
	  
	  @perpData= ($curLali,$curPid,$curDer,$dist);
	  
	}
	
      }
    }
    
    
  }

  $perpData[3]=round(100* $perpData[3])/100;
  
  #print STDERR "$aliSeq\t$lali\t$pid\t$perpData[2]\t$perpData[3]\t$tmpData\n";
  #print STDOUT "$aliSeq\t$lali\t$pid\t$perpData[2]\t$perpData[3]\t$tmpData\n";

  return($perpData[3],"ok $sbrName");
  
}


  
  
  