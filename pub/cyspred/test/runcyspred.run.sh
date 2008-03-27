#!/bin/sh
#                                       wind  Ent Hyd Charg Weight
#../bin/Profil ../FILE/<protp>. trainbox.p 11   1   0   0     0
#

# general
cp $1 ./1mia_
cp $2 ./1mia.hssp
$CYSPREDIR/bin/mkNspi.pl ./1mia_ > ./1mia_.Nspi
#
#net 0
#
$CYSPREDIR/bin/Profil 1mia_ trainbox.p 11 1 0 0 1 >/dev/null
cp $CYSPREDIR/253_23_11/NETDEF.NET .
cp $CYSPREDIR/253_23_11/WEIGHT.BIN .
$CYSPREDIR/bin/net 0 >/dev/null
mv ./scrittura ./net0.out
#
#net 1
#
$CYSPREDIR/bin/Profil 1mia_ trainbox.p 15 1 0 1 1 >/dev/null
cp $CYSPREDIR/375_25_15/NETDEF.NET .
cp $CYSPREDIR/375_25_15/WEIGHT.BIN .
$CYSPREDIR/bin/net 0 >/dev/null
mv ./scrittura ./net1.out
#
#net 2
#
$CYSPREDIR/bin/Profil 1mia_ trainbox.p 17 0 0 0 1 >/dev/null
cp $CYSPREDIR/391_23_17/NETDEF.NET .
cp $CYSPREDIR/391_23_17/WEIGHT.BIN .
$CYSPREDIR/bin/net 0 >/dev/null
mv ./scrittura ./net2.out
#
#net 3
#
$CYSPREDIR/bin/Profil 1mia_ trainbox.p 15 1 1 0 1 >/dev/null
cp $CYSPREDIR/660_44_15/NETDEF.NET .
cp $CYSPREDIR/660_44_15/WEIGHT.BIN .
$CYSPREDIR/bin/net 0 >/dev/null
mv ./scrittura ./net3.out
#
#net 4
#
$CYSPREDIR/bin/Profil 1mia_ trainbox.p 15 1 1 1 1 >/dev/null
cp $CYSPREDIR/690_46_15/NETDEF.NET .
cp $CYSPREDIR/690_46_15/WEIGHT.BIN .
$CYSPREDIR/bin/net 0 >/dev/null
mv ./scrittura ./net4.out
#
# jury
#
$CYSPREDIR/bin/juryR.pl ./1mia_.Nspi net*.out > Results.out 
#
# delete everything
#
rm -f ./1mia* ./net*.out ./NETDEF.NET ./WEIGHT.BIN ./trainbox.p ./fil-pes_ab.dat ./num.cys

if [ $# -gt 2  ]
then
   mv ./Results.out $3
fi


