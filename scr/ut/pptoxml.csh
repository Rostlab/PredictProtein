#!/bin/sh
cmmd="java -classpath $HOME/dev.2.0 pptoxml "
foreach name in "$@"
     cmmd="$cmmd $name"
end 
echo $cmmd

#sequence=tx2.fasta prof=tx2.profRdb nors=tx2.nors phdhtm=tx2.phdPred disulfind=tx2.disulfind globe=tx2.globeProf prosite=tx2.prosite seg=tx2.segNorm asp=tx2.asp
#java -classpath $HOME/dev.2.0 pptoxml $1 sequence=NP_416743.fasta phdhtm=NP_416743.phdPred
