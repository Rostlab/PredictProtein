#!/bin/sh

if [ $# -lt 4 ]
then
	echo "Usage: `basename $0` <protein.fasta> <protein.psi2> <protein.output> <ascii|html>"
	exit 1
fi

# get command line arguments
queryfile=$1
psifile=$2
outfile=$3
format=$4
qfile=`basename $queryfile`
alternatives=3 # fix number or alternative patterns

# set working directories
DISULFIND=/nfs/data5/users/ppuser/server/pub/disulfind
rootdir=$DISULFIND
#rootdir=$PWD
bindir=$rootdir/bin
wdir=$rootdir/tmp/
psiblastdir=$rootdir/PsiBlast
modeldir=$rootdir/Models
pdir=$rootdir/Predictions

# set working environment
OLD_PATH=$PATH
export PATH=$bindir:$PATH
OLD_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$rootdir/src/stlport4.5-4.5.3/lib/

echo "Getting profile for sequence"
echo "$qfile"

### Compute Profile ####
echo "cp $psifile $psiblastdir/Pssm/$qfile"
cp $psifile $psiblastdir/Pssm/$qfile
cd $bindir
## check if there is any cysteine, otherwise exit now
sequence=`$bindir/prot_reader -f $psifile -t PSI2 -a | tr -d '\n' | tr -d ' '`

if [ `$bindir/prot_reader -f $psifile -t PSI2 -a | grep C | wc -l` -lt 1 ]
then
	echo "$bindir/defaultOutput.pl $sequence $qfile > $outfile"
	$bindir/defaultOutput.pl $sequence $qfile > $outfile	
	exit 0
fi

# primary sequence is in $qfile, test profiles are in $wdir/PsiBlast/Pssm (to be converted)
echo "$bindir/createDataKernel.sh 7 $qfile $modeldir/freq_mean $modeldir/freq_stddev $modeldir/length_mean $psiblastdir/Pssm/ > $wdir/$qfile"
$bindir/createDataKernel.sh 7 $qfile $modeldir/freq_mean $modeldir/freq_stddev $modeldir/length_mean $psiblastdir/Pssm/ > $wdir/$qfile

### Predict bonding state ###
## svm prediction
model=$modeldir/kernel.model
prediction=$wdir/$qfile.kernel.prediction
echo "$bindir/svm_classify $wdir/$qfile $model $prediction > /dev/null"
$bindir/svm_classify $wdir/$qfile $model $prediction > /dev/null

## brnn prediction
probability=$wdir/$qfile.kernel.probability
less ${prediction} | perl -e 'while(defined($row=<>)){print 1 / (1+exp(-$row)) . "\n"}' > ${probability}
config=$modeldir/brnn.config
model=$modeldir/brnn.model
graph=$qfile.graph

# Create datafile for brnn bonding state predictor 
echo "$bindir/createDataBRNN.pl $queryfile $probability $psiblastdir/Pssm/$qfile $wdir/$graph"
$bindir/createDataBRNN.pl $queryfile $probability $psiblastdir/Pssm/$qfile $wdir/$graph 

# Predict bonding state through brnn
prediction=$pdir/Bondstate/BRNN/$qfile
testlist=$wdir/testlist
echo "$graph" > $testlist
echo "$bindir/predBondState -c $config -n $model -d $wdir --test-set $testlist | grep '.' | awk '{print 1-$1,$1}' > $prediction"
$bindir/predBondState -c $config -n $model -d $wdir --test-set $testlist | grep '.' | awk '{print 1-$1,$1}' > $prediction


### FILTER OUTPUT (non-consistent predictions) ###
viterbiprediction=$pdir/Bondstate/Viterbi/$qfile
model=$modeldir/automa.model 
echo "$bindir/viterbi_aligner $model $prediction | cut -d ' ' -f 2 > $viterbiprediction"
$bindir/viterbi_aligner $model $prediction | cut -d ' ' -f 2 > $viterbiprediction


### Predict connectivity ###
# get number of bridges
B=`grep 1 $viterbiprediction | wc | awk '{print $1}'`
B=$((B/2))
#echo $B
# Control number of bonds
# Assume Viterbi decoder has corrected inconsistencies
prediction=$pdir/Connectivity/$qfile
if [ $B -ne 0 ]
then
  if [ $B -lt 6 ]
  then
    if [ "$B" -eq 1 ]
    then
      echo "echo 1 2 > $prediction"
      echo "1 2" > $prediction
    else 
      # Create datafile for brnn connectivity predictor
      brnndir=$rootdir/ConnPred
    
      cd $brnndir
      echo "./seq2conngraphs $qfile $pdir/Bondstate/Viterbi/ $psiblastdir/Pssm/ $brnndir/data/sequences_w5/ $brnndir/data/graphs/ 5"
      ./seq2conngraphs $qfile $pdir/Bondstate/Viterbi/ $psiblastdir/Pssm/ $brnndir/data/sequences_w5/ $brnndir/data/graphs/ 5
      cd $rootdir
    
      echo "$qfile" > $brnndir/data/$B/test
      echo "$brnndir/predictpattern -c $brnndir/data/$B/conf -n $brnndir/data/$B/net -d $brnndir/data/graphs/ --train-set $brnndir/data/$B/train --test-set $brnndir/data/$B/test > $prediction"
      $brnndir/predictpattern -c $brnndir/data/$B/conf -n $brnndir/data/$B/net -d $brnndir/data/graphs/ --train-set $brnndir/data/$B/train --test-set $brnndir/data/$B/test > $prediction
    fi
  else
    echo "too many bridges"
  fi
fi

## Assemble output
prediction=$pdir/All/$qfile
echo "#bonds" > $prediction
paste $pdir/Bondstate/Viterbi/$qfile $pdir/Bondstate/BRNN/$qfile >> $prediction

if [ -e "$pdir/Connectivity/$qfile" ]
then
  echo "#bridges" >> $prediction
  cat $pdir/Connectivity/$qfile >> $prediction
fi

if [ "$format" ==  "ascii" ]
then
    echo "$bindir/makeASCIIOutput.pl $sequence $prediction $alternatives $qfile > $outfile"
    $bindir/makeASCIIOutput.pl $sequence $prediction $alternatives $qfile > $outfile
else
    echo "$bindir/makeHTMLOutput.pl $sequence $prediction $alternatives $qfile > $outfile"
    $bindir/makeHTMLOutput.pl $sequence $prediction $alternatives $qfile > $outfile
fi
    
#cleanup
export PATH=$OLD_PATH
export LD_LIBRARY_PATH=$OLD_LD_LIBRARY_PATH

echo "Cleaning up temporary files"
rm -f $wdir/*
