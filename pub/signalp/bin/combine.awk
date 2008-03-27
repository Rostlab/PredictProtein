#! /usr/bin/nawk -f

BEGIN {
	if (format=="short") {
		printf "# SignalP %s predictions\n", group
		print "# name       Cmax  pos ?  "\
			"Ymax  pos ?  Smax  pos ?  Smean ?"
	}
	else {
	printf "************************* SignalP predictions "
	printf "*************************\n"
	printf "Using networks trained on %s data\n", group

	#printf "\nC = raw cleavage site score\n"
	#printf "S = raw signal peptide score\n"
	#printf "Y = combined cleavage site score:  Y = sqrt(C*(-delta S)),\n"
	#printf "    where delta S is averaged over a window " \
	#	"of 2*%d positions\n\n", drange
	}
}

NR=1 { 	
	# In gawk (a.o.) command line variable assignments has not taken
	# effect in the BEGIN clause
	split(Cscales, Cwt, ",")
}

/^ #/ { 
	N++
	len = substr($0,30,6)+0 
	name = substr($0,7,11)
	seq = ""
}

/SINGLE/ { 
	out=1 
	next
}

(out) {
	C[$1] = S[$1] = 0
	for (i=0; i<5; i++) {
		C[$1] += $(6*i+5)*Cwt[i+1]
		S[$1] += $(6*i+35)
	}
	C[$1] /= 5
	if (C[$1]>1) C[$1]=1
	S[$1] /= 5
	seq = seq $2
}

out && $1 == len { 
	out=0
	if (format=="long") {
		printf "\n>%s  length = %d\n\n", name, len
		print "# pos  aa    C       S       Y"
	}
	Cmax = Smax = Ymax = 0
	Cmaxpos = Smaxpos = Ymaxpos = 1
	for (i=1-drange; i<=0; i++)
		S[i]=S[1]
	for (i=len+1; i<=len+drange; i++)
		S[i]=S[len]
	for (i=1; i<=len; i++) {
		diff = 0
		for (j= i-drange; j<i; j++)
			diff += S[j]
		for (j= i; j< i+drange; j++)
			diff -= S[j]
		diff /= drange
		Y = (diff>0) ? sqrt(C[i]*diff) : 0
		if (Y>Ymax) { Ymax=Y; Ymaxpos=i }
		if (S[i]>Smax) { Smax=S[i]; Smaxpos=i }
		if (C[i]>Cmax) { Cmax=C[i]; Cmaxpos=i }
		if (format=="long") {
			printf "%5d   %1s   %5.3f   %5.3f   %5.3f\n", 
				i, substr(seq,i,1), C[i], S[i], Y 
		}
	}
	Smean = 0
	for (i=start; i<=Ymaxpos-1; i++)
		Smean += S[i]
	if (Ymaxpos>1)
		Smean /= (Ymaxpos - 1)
	else
		Smean = 0

	if (format=="short") {
		printf "%-10s  ", name
		printf "%5.3f %3d %1s  ", 
			Cmax, Cmaxpos, (Cmax>Cmaxcut) ? "Y" : "N"
		printf "%5.3f %3d %1s  ", 
			Ymax, Ymaxpos, (Ymax>Ymaxcut) ? "Y" : "N"
		printf "%5.3f %3d %1s  ", 
			Smax, Smaxpos, (Smax>Smaxcut) ? "Y" : "N"
		printf "%5.3f %1s\n", 
			Smean, (Smean>Smeancut) ? "Y" : "N"
		next
	}
	printf "\n< Is the sequence a signal peptide?\n"
	printf "# Measure  Position  Value  Cutoff  Conclusion \n"
	printf "  max. C   %3d       %5.3f  %5.2f   %s\n",
		Cmaxpos, Cmax, Cmaxcut, (Cmax>Cmaxcut) ? "YES" : "NO"
	printf "  max. Y   %3d       %5.3f  %5.2f   %s\n",
		Ymaxpos, Ymax, Ymaxcut, (Ymax>Ymaxcut) ? "YES" : "NO"
	printf "  max. S   %3d       %5.3f  %5.2f   %s\n",
		Smaxpos, Smax, Smaxcut, (Smax>Smaxcut) ? "YES" : "NO"
	printf "  mean S     1-%-4d  %5.3f  %5.2f   %s\n",
		Ymaxpos-1, Smean, Smeancut, (Smean>Smeancut) ? "YES" : "NO"
	if (Smax>Smaxcut || Ymax>Ymaxcut || Smean>Smeancut) {
	printf "# Most likely cleavage site between pos. %d and %d: %s\n",
		Ymaxpos-1, Ymaxpos,
		substr(seq,Ymaxpos-3,3) "-" substr(seq,Ymaxpos,2)
	}
	print ""
}
