#!/bin/sh

if [ $# -lt 2 ]
then
	echo "Usage: `basename $0` <query> <queryid>" 
	exit 1
fi

#rootdir=$PWD
rootdir=$PP_PUB/disulfind
bindir=$rootdir/bin
wdir=$rootdir/tmp/
psiblastdir=$rootdir/PsiBlast
modeldir=$rootdir/Models
pdir=$rootdir/Predictions
querydir=$pdir/Queries
fastadir=$rootdir/Fasta
outdir=$pdir/Outputs
answerdir=$pdir/Answers
logdir=$rootdir/Logs

### Save query file ###
query=$1
qfile=$2
queryfile=$querydir/$qfile
logfile=$logdir/$qfile
fastafile=$fastadir/$qfile

# save query to queryfile
cp $query $queryfile 

### Parse query file and get user data ###
idseq=""
predict=1
format=html 
alternatives=1

if [ $predict -eq 1 ]
then 
    echo "$bindir/disulfinder -r $rootdir -a $alternatives -p $queryfile -o $outdir -F $format" >> $logfile
    $bindir/disulfinder -r $rootdir -a $alternatives -p $queryfile -o $outdir -F $format >> $logfile
else
    echo $bstate | tr ' ' '\n' | grep -e "[01]" > $pdir/Bondstate/Viterbi/$qfile
    echo "$bindir/disulfinder -r $rootdir -a $alternatives -f $fastafile -o $outdir -F $format -C" >> $logfile
    $bindir/disulfinder -r $rootdir -a $alternatives -f $fastafile -o $outdir -F $format -C  >> $logfile   
fi

# cleanup html output 
if [ "$idseq" != "" ]
then
    cat $outdir/$qfile | grep -e Copyright -e html -v | sed s/$qfile/$idseq/ > $answerdir/$qfile
else
    cat $outdir/$qfile | grep -e Copyright -e html -v > $answerdir/$qfile
fi

if [ "$format"  == "ascii" ]; then
    # mail message
    SUBJECT="Cysteines bonding state prediction"
    if [ "$idseq" != "" ]
    then
	SUBJECT="${SUBJECT} - Chain identifier: ${idseq}" 
    fi
    echo "cat $answerdir/$qfile | mail -s \"$SUBJECT\" $email" > $logfile
    cat $answerdir/$qfile | mail -s "$SUBJECT" $email
fi

# send output to stdout
cat $answerdir/$qfile

# remove tempfiles
unlink $answerdir/$qfile
unlink $pdir/All/$qfile
unlink $pdir/Connectivity/$qfile
unlink $pdir/Queries/$qfile
unlink $outdir/$qfile
unlink $pdir/Bondstate/BRNN/$qfile
unlink $pdir/Bondstate/Viterbi/$qfile
