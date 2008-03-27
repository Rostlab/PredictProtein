#! /usr/bin/perl -w
## for a list of swiss id's, generate keyword vectors and localize proteins if possible!
#use Math::MatrixReal qw(:all);
$scr=$0;

print "exe $0\n";

$scr=$0;
$scr=~m /^(.*\/).*?/;
$par{'dirHome'}=                       $1; # the home dir ..w
$par{'fileOut'}=                       "protLoc.rdb"; # the output file with localization!
$par{'fileKeyList'}=                   "KeyList.rdb";# list of keywords(unflagged) in swiss for each protein
$par{'fileErr'}=                       "protLoc.err"; #out file for proteins which could not be localized (below specified threshold)

$par{'dirDb'}=                         $par{'dirHome'}."db/";#the dir with Keywords database.
$par{'vecDb'}=                         $par{'dirDb'}."KeyWdComp.rdb";# the database with vectors for known localizations!
$par{'locDb'}=                         $par{'dirDb'}."KeyLocStat.rdb";
$par{'fileFlag'}=                      "No";#the file with flagged keywords
#$par{'flagDb'}=                        "/hosts/magnolia/magnolia2/nair/work/proj_loci_swiss/KeyWdAnalysis/TestNew/flagDb.rdb";
$par{'keyindex'}=                      "/data/swissprot/keyindex.txt";  #the swiss-prot keywords file
$par{"fileHom"}=                       "No";# no homologs file porvided ..for unknown loci test set.
$par{'minNum'}=                         5; #min num of proteins in which the given keyword combination must be found
$par{'maxKey'}=                         9; #if more than this no of keywords are detected, only the best maxKey no of keywords are used
#$par{'thresh'}=                        75;#the pid thresh for homologs!
$par{'thresh'}=                        15;#the hssp thresh for homologs!
$par{'fracEnt'}=                       70;#the fractional change in entropy above which proteins are considered localized.
$par{'jobId'}=                         "";


undef @keyDb; undef %keyDb; undef @dataDb; undef %protKey; undef %locDb;undef %bigKey;undef %flagDb;
#$locDb{'unk'}=1; #an additional loc type fro proteins which cannot be localized!

$fhin="FHIN";
$fhData= "FHDATA";
$fhout= "FHOUT";
$fhErr= "FHERR";
$fhoutKey= "FHKEY";

if($#ARGV <0 ){
  print STDERR "use: scr list(list of swiss id's)\n";

  exit;
}

$fileIn= $ARGV[0];#list of swiss id's


if(!-r $fileIn){
  print STDERR "could not open $fileIn\nexiting program\n";
  exit;
}

foreach $i (1..$#ARGV){

  if($ARGV[$i]=~ /(.*)=(.*)/){
    $arg=$1;
    $val=$2;
    print "arg=$1\tval=$2\n";
    if(defined $par{$arg}){# accepted argument!
      $par{$arg}=$val;
      print STDERR "$arg set to $val\n";
      print  "$arg set to $val\n";
    }
    else{#input not right
      print STDERR "unacceptable argument $arg\n check input\n";
      print  "unacceptable argument $arg\n check input\n";
      exit;
    }

  }
  else{
      print STDERR "unacceptable input\nno arguments provided\n";
      print  "unacceptable input\nno arguments provided\n";
      exit;

  }

}

#append jobId to output files
$par{'fileOut'}.= $par{'jobId'};
$par{'fileKeyList'}.= $par{'jobId'};
$par{'fileErr'}.= $par{'jobId'};

if (-e $fileIn) {
  open($fhin, $fileIn) || die "** could not open $fileIn\n";
  while (<$fhin>) {
  
    next if /^\#/;
    @tmp=split(/[\s]+/,$_);
    $id= $tmp[0];
    $loc= $tmp[1];
    $protDb{$id}=1;
    $bigDb{$id}=1;#add prot to big (prot + hom)
  }
}
else{
  print STDERR "could not open in file = $fileIn\n";
  print  "could not open in file = $fileIn\n";
  exit;
}

close($fhin);

if($par{'fileFlag'} !~ /^No/){#file with keywords to be exculded provided
  open($fhin, $par{'fileFlag'}) || eval{print STDERR "$scr could not open provided flagged keyword file=$par{'fileFlag'}\nStart again!\n";
					print  "$scr could not open provided flagged keyword file=$par{'fileFlag'}\nStart again!\n";
					print $fhErr "$scr could not open provided flagged keyword file=$par{'fileFlag'}\n";
					exit;
				      };

  while(<$fhin>){
    next if /^\#/;
    @tmp=split(/\t/,$_);
    $flagDb{$tmp[0]}=1;#this keyword is excl
  }

  close $fhin;
}

if($par{"fileHom"} !~ /^No/){#homologs (blastProcess output) file provided
  open($fhin, $par{"fileHom"}) || eval{ print STDERR "$scr could not open provided loci file=$par{'fileHom'}\nStart again!\n";
					 print  "$scr could not open provided loci file=$par{'fileHom'}\nStart again!\n";
					print $fhErr "$scr could not open provided loci file=$par{'fileHom'}\n";
					exit;
				      };

  while (<$fhin>) {
    next if /^\#|id1/;
    @tmp=split(/[\s]+/,$_);
    $id= $tmp[0];

    #parse homologs list
    if (defined $protDb{$id}) {	#this id in protDb
      if (defined $tmp[2]) {
	if (!defined $tmp[3]) {	#consider all in list as homologs
	  @idList=split(/,/,$tmp[2]);
	  foreach $li (@idList) {
	    $homDb{$id}{$li}=1; # the homologs Db
	    $bigDb{$li}=1;
	  }
	} else {		#parse hom list to extract good homologs
	  @idList=split(/,/,$tmp[2]);
	  @disList=split(/,/,$tmp[3]);
	  if ($#idList != $#disList) {
	    print STDERR "num prot= $#idList not equal to num pid's= $#disList for id =$id\n";
	    print STDERR "check input file format!\n";
	    print  "check input file format!\n";
	    exit;
	  }
	  foreach $j (0..$#disList) {
	    if ($disList[$j]>=$par{'thresh'}) {
	      $homDb{$id}{$idList[$j]}=1; # the good homologs
	      $bigDb{$idList[$j]}=1;
	    }
	  }
	}
      }
    }
  }
  close $fhin;

}



#foreach $id (keys %protDb){
#  print STDERR "$id\t";
#  foreach $k (keys %{$homDb{$id}}){
#    print STDERR "$k,";
#  }
#  print STDERR "\n";
#}
#exit;
# read vector Database
if(!-r $par{'vecDb'}){
  print STDERR "could not open vector Db= $par{'vecDb'}\nexiting program\n";
  print  "could not open vector Db= $par{'vecDb'}\nexiting program\n";
  exit;
}


open($fhData, $par{'vecDb'})  || eval{print "** could not open $par{'vecDb'}\n"; exit;};

$count=0;

undef @dbMat;
while(<$fhData>){
  if(/^\#/){
    if(/^\#protId/){
      chomp;
      @tmp=split(/\t/,$_);

      foreach $i (4..$#tmp){
	$keyDb{$tmp[$i]}=1;#the list of keywords in Db!
	push @keyDb, $tmp[$i]; # keeps track of keyword ordering
      }
      next;
    }
    else{
      next;
    }
  }
  #proc prot

  @tmp=split(/\t/,$_);
  chomp;
  $dataDb[$count]{'id'}=$tmp[0];
  $dataDb[$count]{'loc'}=$tmp[1];
  if(! defined $locDb{$tmp[1]}){
    $locDb{$tmp[1]}=1; # the different localization types
  }
  else{
    $locDb{$tmp[1]}++;
  }

  foreach $i (4..$#tmp){
    if($tmp[$i]==1){
      $hashInd= $i-4;
      $dbMat[$count]{$hashInd}=1;#hash implementation to cut down on memory usage
    }

  }
  $count++;
}
close $fhData;

if(!-r $par{'locDb'}){
  print STDERR "could not open vector Db= $par{'locDb'}\nexiting program\n";
  print  "could not open vector Db= $par{'locDb'}\nexiting program\n";
  exit;
}


open($fhData, $par{'locDb'})  || eval {print "** could not open $par{'locDb'}\n";exit;};
while(<$fhData>){

  if(/^\#keyWd/ && /fracSI/){
    s/^\#//;
    @tmp=split(/[\s+]/,$_);
    foreach $i (0..4){
      if($tmp[$i]=~ /keyWd/){
	$keyWd= $i;
      }
      elsif($tmp[$i]=~ /fracSI/){
	$fracSI= $i;
      }
    }
    next;
  }elsif(/^\#/){
    next;
  }
  else{
    chomp;
    @tmp=split(/\t/,$_);
    $siDb{$tmp[$keyWd]}=$tmp[$fracSI];
  }

}

#foreach $keys (keys %keyDb){
#  print STDERR "$keys\n";
#}

$numDbMat= $#keyDb; #length of keys array, same as num col in dbMat
#now the max entropy
$numLoc=keys %locDb;
$entMax=0;
foreach $loc (keys %locDb){
  $frac=1/$numLoc;
  $entMax+=-$frac*log($frac)
}
$entMax=int(1000*$entMax)/1000;

#now read the keywords file!
open($fhData,$par{'keyindex'}) || eval{ print STDERR "$scr could not open keyindex file=$par{'keyindex'}\nStart again!\n";
					print "$scr could not open keyindex file=$par{'keyindex'}\nStart again!\n";
					print $fhErr "$scr could not open keyindex file=$par{'keyindex'}\n";
					exit;
				      };

$begInd= 0;
undef $keyWdCur;
$keyFlag=0;
print STDERR "reading swiss keywords file $par{'keyindex'}\n";
print  "reading swiss keywords file $par{'keyindex'}\n";

DAT:
while(<$fhData>){

  if($_=~ /^---/){

    $begInd++;
    next DAT;
    
  }
  elsif($begInd == 3){
    next DAT if($_ !~ /\w/);
    if(/^\w+/){# means a keyword!!
      m/^(.+)\s/;
      $keyWdCur= $1;
      if(defined $keyDb{$keyWdCur} && ! defined $flagDb{$keyWdCur}){
	#print STDERR "$keyWdCur\n";
	$keyFlag=1;
      }
      else{
	$keyFlag=0;
      }
      next DAT;
    }
    elsif($keyFlag==1){# protein lists for keywords in Db
      $lineIn=$_;
      $lineIn=~s/\s+//g;
      @tmp=split(/,/,$lineIn);
      foreach $i (0..$#tmp){
	
	$tmp[$i]=~m/^(\w+)/;
	$swissId=$1;
	$swissId=~tr/[A-Z]/[a-z]/;
	if(defined $bigDb{$swissId}){#prot in prot+hom Db
	  $bigKey{$swissId}{$keyWdCur}=1;
	
	}

      }
    }
  }
  elsif($begInd > 3){
    last DAT;
  }
  else{
    next DAT;
  }
  

}
close $fhData;

open($fhoutKey,">".$par{'fileKeyList'}) || die "**could not open out file=$par{'fileKeyList'}\n";
print $fhoutKey "#out gen by $0\n";
print $fhoutKey "#protId\tloc\tkeyWdList\n";


#open out file
open($fhout,">".$par{'fileOut'}) || die "could not open fileOut=$par{'fileOut'}\n";
open($fhErr,">".$par{'fileErr'})  || die "could not open fileErr=$par{'fileErr'}\n";
print $fhout "#out gen by scr= $0\n";
print $fhErr "#out gen by scr= $0\n";
print $fhout "#the pid threshold for homologs= $par{'thresh'}\n";
print $fhErr "#the pid threshold for homologs= $par{'thresh'}\n";
print $fhout "#the fractional change in entropy above which proteins are considerd localized= $par{'fracEnt'}\n";
print $fhErr "#the fractional change in entropy above which proteins are considerd localized= $par{'fracEnt'}\n";
print $fhout "#proteinId\tFracEnt\tNormFracEnt\tNumProt";
print $fhErr "#proteinId\tFracEnt\tNormFracEnt\tNumProt";
foreach $loci (sort keys %locDb,"unk"){
  print $fhout "\t$loci";
  print $fhErr "\t$loci";
}

print $fhout "\n";
print $fhErr "\n";
#now proc each prot!


#now join keywords
foreach $prot (keys %protDb){
  #print STDERR "$prot\t";
  foreach $keyWd (keys %{$bigKey{$prot}}){
    $protKey{$prot}{$keyWd}=1;
  }
  if(defined $homDb{$prot}){
    foreach $hom (keys %{$homDb{$prot}}){
      # print STDERR "$hom,";
      foreach $keyWd (keys %{$bigKey{$hom}}){
	$protKey{$prot}{$keyWd}=1;
      }
    }
  }
#find num keys in prot and process

  $numKey= keys %{$protKey{$prot}};
  #now print out the keywords for this protein
  if($numKey>0){
    undef $keyStack;
    foreach $keyWd (keys %{$protKey{$prot}}){
      if(defined $keyStack){
	$keyStack.=",$keyWd";
      }
      else{
	$keyStack=$keyWd;
      }
    }
    print $fhoutKey "$prot\tunk\t$keyStack\n";
  }
  else{
    print $fhoutKey "$prot\tunk\n";
  }
  
  if($numKey>$par{'maxKey'}){#pick best keys
    @keyTmp= keys %{$protKey{$prot}};
    @keySort= sort {$siDb{$b}<=>$siDb{$a}}(@keyTmp);
    
    foreach $it ($par{'maxKey'}..$#keySort){
      delete $protKey{$prot}{$keySort[$it]};
      #print STDERR "deleted $keySort[$it]\n";
    }

  }
#  @homTmp= keys %{$homDb{$prot}};
#  @keyTmp= keys %{$protKey{$prot}};
#  print STDERR "$prot\t@homTmp\t@keyTmp\n";
}


undef %bigKey; #memory manage
#%protKey contains the merged keywords

foreach $prot (sort keys %protDb){

  undef %protVec;undef @lenDb;undef @subVecMat;undef @stat;undef @norm;undef @max;undef @maxEnt;undef %foundKey;undef $fi;
  print  STDERR "proc prot= $prot\n";
  print   "proc prot= $prot\n";
  
  $numKey= keys %{$protKey{$prot}};
  if(! defined $protKey{$prot} || $numKey==0 ){# no keywords from Db found in prot + hom
    print $fhErr "$prot\t0\t0\t0";
    print STDERR "$prot\t";
    foreach $loci (sort keys %locDb,"unk"){
      if($loci=~ /unk/){
	print $fhErr "\t100";
      }
      else{
	print $fhErr "\t0";
      }
    }
    print $fhErr "No Keywords\n";
    print STDERR "No Keywords\n";
  }
  else{
    # now proc prot for which keywords were found!
    # first make the vectors

    foreach $i (0..$#keyDb){
      
      if(defined $protKey{$prot}{$keyDb[$i]} && $protKey{$prot}{$keyDb[$i]}==1){
	$protVec{$i}=1;
	$foundKey{$keyDb[$i]}=1;
      }
    }
    $numKey= keys %protVec;
    print STDERR "no of keys in prot= $numKey\n";
    print  "no of keys in prot= $numKey\n";
    # pass vector to subrountine to make combinations (generate sub vectors)
    ($subVec,$subLen)=genSubSparse(\%protVec);
    @lenDb= @$subLen;
    $vecLen=$#keyDb;
    foreach $x (0..$#{$subVec}){
      foreach $y (0..$vecLen){
	if(defined $$subVec[$x]{$y}){
	  $subVecMat[$y]{$x}=1;
	}
      }
    }
    print STDERR "###Generated subvectors and assigned them\n";
      $colMat= $#{$subVec};
      
    ($prod)=&matrixProd(\@dbMat,$numDbMat,\@subVecMat,$vecLen,$colMat);

    print STDERR "grenerated product matrix\n";
    print  "grenerated product matrix\n";
    #verify generated product matrix
    #  foreach $x (0..$#{$prod}){
    #    foreach $y (0..$#{$$prod[0]}){
    #      if(!defined $$prod[$x][$y] ){
    #	print STDERR "x=$x\ty=$y\n";
    #      }
    #    }
    #  }
    
    #now gen statistics
    
    foreach $i (0..$colMat){
      $stat[$i]{'tot'}=0;
      foreach $j (0..$#dataDb){
	
	if(defined $$prod{$j}{$i} && $$prod{$j}{$i} == $lenDb[$i]){
	  # a match
	  $stat[$i]{$dataDb[$j]{'loc'}}++;
	  $stat[$i]{'tot'}++;
	}
	
      }
            
      #now cal entropy
#      if($stat[$i]{'tot'}==0){
#	print STDERR "num prot=0 for i=$i\n";
#	print STDERR "keyword motif= @{$$subVec[$i]}\n";
#	foreach $j (0..$#{$$subVec[$i]}){
#	  if ($$subVec[$i][$j]==1){
#	    print STDERR "$keyDb[$j]\t";
#	  }
	
#	}
#    }

      $stat[$i]{'ent'}=0;
      $stat[$i]{'frCh'}=0;
      $norm[$i]{'ent'}=0;
      $norm[$i]{'frCh'}=0;
      if($stat[$i]{'tot'}>0){
	foreach $loc (keys %locDb){
	
	  if(defined $stat[$i]{$loc}){
	    $norm[$i]{$loc}=$stat[$i]{$loc}/$locDb{$loc};
	    $norm[$i]{'sum'}+=$norm[$i]{$loc};
	    $frac= $stat[$i]{$loc}/$stat[$i]{'tot'};
	    if($frac>0){
	      $stat[$i]{'ent'}+=-$frac*log ($frac);
	    }
	    $stat[$i]{$loc}=int(10000*$frac)/100;
	  }
	  else{
	    $stat[$i]{$loc}=0;
	  }
	}
	foreach $loc (keys %locDb){
	  if(defined $norm[$i]{$loc} && $norm[$i]{$loc}>0){
	    $normFrac=$norm[$i]{$loc}/$norm[$i]{'sum'};
	    $norm[$i]{'ent'}+=-$normFrac * log $normFrac;
	  }
	}
      }
      else{
	$stat[$i]{'ent'}=$entMax;
	$norm[$i]{'ent'}=$entMax;
	foreach $loc (keys %locDb){
	  $stat[$i]{$loc}=0;
	}
      }
      $stat[$i]{'frCh'}=int (10000*($entMax - $stat[$i]{'ent'})/$entMax)/100;
      $stat[$i]{'ent'}=int(1000*$stat[$i]{'ent'})/1000;
      $norm[$i]{'frCh'}=int (10000*($entMax - $norm[$i]{'ent'})/$entMax)/100;
      $norm[$i]{'ent'}=int(1000*$norm[$i]{'ent'})/1000;

      $max[$i]=$stat[$i]{'frCh'};
      
    }
    #now find min entropy!
    #  print STDERR "@max\n@lenDb\n";
    print STDERR "###working ont he statistics\n";
    @maxEnt= sort {$max[$a]<=>$max[$b] or $norm[$a]{'frCh'}<=>$norm[$b]{'frCh'} or $stat[$a]{'tot'} <=> $stat[$b]{'tot'}} (0..$#max);

    #print STDERR "maxEnt=@maxEnt\nmax=@max\n";
    #foreach $it (0..$#max){
    #	print STDERR "$stat[$it]{'tot'} ";
    #}	
    #print STDERR "\n";
  #find best that meets min num criteria!
  BEST:
    for($z=$#maxEnt;$z>=0;$z--){
      $it=$maxEnt[$z];
      if($stat[$it]{'tot'}>=$par{'minNum'}){
	$fi=$it;
	last BEST;
      }
    }	
    #$fi= $maxEnt[$#maxEnt];
    
    #print STDERR "@maxEnt\n";
 

    #is this any good?
    if(!defined $fi || $max[$fi]<$par{'fracEnt'}){
      if(!defined $fi){
	$fi=$maxEnt[$#maxEnt];
      }	
      print $fhErr "$prot\t$max[$fi]\t$norm[$fi]{'frCh'}\t$stat[$fi]{'tot'}\t";
      print STDERR "$prot\t$fi\t$max[$fi]\tno pred\n";
      foreach $loci (sort keys %locDb,"unk"){
	if($loci=~ /unk/){
	  print $fhErr "100\t";
	}
	else{
	  print $fhErr "$stat[$fi]{$loci}\t";
	}
      }
      undef $keyStr;
      foreach  $nit (keys %foundKey){
	if(!defined $keyStr){
	  $keyStr="$nit";
	}
	else{
	  $keyStr.=",$nit";
	}
      }
      
      print $fhErr "$keyStr\n";


    }
    else{
      
      #if here good prediction!!
      print $fhout "$prot\t$max[$fi]\t$norm[$fi]{'frCh'}\t$stat[$fi]{'tot'}\t";
      print STDERR "$prot\t$max[$fi]\t$norm[$fi]{'frCh'}\t$stat[$fi]{'tot'}\t";
      foreach $loc (sort keys %locDb,"unk"){
	if($loc !~ /unk/){
	  print $fhout "$stat[$fi]{$loc}\t";
	  print STDERR "$stat[$fi]{$loc}\t";
	}
	else{
	  print $fhout "0\t";
	  print STDERR "0\t"
	}
      }
      
      undef $keyStr;
      foreach  $nit (keys %foundKey){
	if(!defined $keyStr){
	  $keyStr="$nit";
	}
	else{
	  $keyStr.=",$nit";
	}
      }
      
      print $fhout "$keyStr\n";
      print STDERR "$keyStr\n";
      }
    }
  undef @$subVec;undef @$subLen; undef @subVecMat;undef %prod;
}


#==============================================================================
#matrixProd sub to calculate product matrix
#==============================================================================
sub matrixProd {
  my($mat1,$lenMat,$mat2,$rowMat,$colMat)=@_;# $mat1 & $mat2 are  arrays of hashes (construct used to cut down space usage)!
  my(%matFin,$x,$y,$i);
  undef %matFin;
  #check if matrices can be multiplied
  if($lenMat != $rowMat){
    print STDERR "matrices could not be multiplied\n";
    print STDERR "num cols= $lenMat \tnum rows $#{$mat2}\n";
    exit;
  }
  print STDERR "in sub matrixProd\n";
  foreach $x (0..$#{$mat1}){
    foreach $y (0..$colMat){

#      foreach $i (0..$lenMat){
#	if(defined $$mat1[$x]{$i}){
#	  $matFin[$x][$y]+=$$mat1[$x]{$i} * $$mat2[$i][$y];
#	}
#	else{
#	  $matFin[$x][$y]+=0;
#	}
#      }

      foreach $i (sort keys %{$$mat1[$x]} ){
	if(defined $$mat2[$i]{$y}){
	  $matFin{$x}{$y}++;
	}
      }
    }
  }
  return(\%matFin);

}

#==============================================================================
#genSubSparse           subroutine to generate all subvectors(in: pointer to a vector)
#==============================================================================
sub genSubSparse {
  my($vector)= @_;
  my(%vector)= %$vector;

  my($i,$vecLen,$fin,@bitTrack,$ind,$j,@lenDb,@vecDb,@tmpVec);
  print STDERR "in sub genSubSparse\n";

  $ind=0;
  %{$vecDb[$ind]}=%vector;
  foreach $i (keys %vector){
    $fin= $#vecDb;
    foreach $j (0..$fin){
      %tmpVec=%{$vecDb[$j]};
      delete $tmpVec{$i};
      $ind++;
      %{$vecDb[$ind]}=%tmpVec;
    }
  }
  delete $vecDb[$#vecDb];
  #now cnt 1's for each vec in db
  foreach $i (0..$#vecDb){
    $lenDb[$i]=keys %{$vecDb[$i]};
  }

  return(\@vecDb,\@lenDb);
}


