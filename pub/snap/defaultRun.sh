
#$ -S /bin/bash -cwd -j y -o defLog -p 0

 perl SingleSequenceRun.pl -i try_snap.fasta -o try_snap.snap -m try_snap.muts -p MC4R_HUMAN/MC4R_HUMAN-fil.rdbProf -x MC4R_HUMAN/MC4R_HUMAN.asci -f MC4R_HUMAN/MC4R_HUMAN.pfam -b MC4R_HUMAN/MC4R_HUMAN.profbval


