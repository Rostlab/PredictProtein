#!/usr/local/bin/perl -w
$name=$ARGV[0];$win=$ARGV[1];$output_file=$ARGV[2];
#$param=0;
#$param=1;
#$param_word=$param;
#$param_word=~s/\./-/;
#$dir=".";
#$dir_out=".";
$file="$name.eprofcon";
open (FILE, "$file") || die "cant open file $!";
undef @disorder;
undef @num;undef @e;undef @aa;undef @sum_e;undef @e_win;undef @hProb;undef @e1;
undef @seq;undef@num;#undef @frac;
while ($line=<FILE>) {
	$line=~ s/\n//;undef@info;
	@info=split (/\t/,$line);
	$aa=$info[1];$num=$info[0];$e=$info[2];$hProb=$info[5];
	push (@seq,$aa);push (@num,$num);push (@e,$e);push (@hProb,$hProb/100);
	}
close (FILE);
$fout=$file;
$fout=~ s/\.eprofcon/\.out/;
#print FOUT "num\taa\te_no_smooth\te_win$win\n";
loop20:for ($i=0;$i<scalar@seq;$i++) {
	$disorder[0][$i]= $disorder[1][$i]= $disorder[2][$i]= $disorder[3][$i]= $disorder[4][$i]='O';
	$st=$i-($win-1)/2;
	$en= $i+($win-1)/2;
	${$count{$win}}[$i]=${$e_win{$win}}[$i]=${$sum_e{$win}}[$i]=0;
loop30:	for ($j=$st;$j<=$en;$j++) {
		if (($j<0)||($j>$#seq)) {
			next loop30;
			}
		${$sum_e{$win}}[$i]=${$sum_e{$win}}[$i]+$e[$j];
		${$count{$win}}[$i]++;
		}
	${$e_win{$win}}[$i]=${$sum_e{$win}}[$i]/${$count{$win}}[$i];
	@e1=convert(\@{$e_win{$win}});
	########old conversion to "probability" values
	
#########################################################################
#	$e1[$i]= ${$e_win{$win}}[$i]+0.15;				#
#	if ($e1[$i]<0) {$e1[$i]=0}					#
#	elsif ($e1[$i]>0.2) {$e1[$i]=1}					#
#	else {								#
#		$e1[$i]=$e1[$i]/0.2;					#
#		}							#
#	if ($e1[$i]>=1) {$disorder[0][$i]='D'}				#
#	if ($e1[$i]>=0.95) {$disorder[1][$i]='D'}			#
#	 if ($e1[$i]>=0.90) {$disorder[2][$i]='D'}			#
#	 if ($e1[$i]>=0.85) {$disorder[3][$i]='D'}			#
#	 if ($e1[$i]>=0.80) {$disorder[4][$i]='D'}			#
#########################################################################
	#else {
#		$disorder[$i]='O';
#		}
	#	$frac[$i]=helix_cont();
	}
open (FOUT,">$output_file") || die "cant open $output_file";
printf FOUT "PFRMAT DR\n";
printf FOUT "TARGET %s\n",$name;
printf FOUT "AUTHOR XXXX-XXXXX-XXXX\n"; 
printf FOUT "REMARK The method predicts long disordered regions in proteins using\n";
printf FOUT "REMARK intra-chain contact prediction and energy potential\n";
printf FOUT "REMARK \n";
printf FOUT "METHOD PreNUP: prediction of natively unstructured proteins\n";
for ($x=0;$x<5;$x++) {
	$j=$x+1;
	printf FOUT "MODEL $j\n";
	for ($i=0;$i<scalar@seq;$i++) {
		printf FOUT "$seq[$i] $disorder[$x][$i] %1.2f\n",$e1[$i] ;
		}
	}
	printf FOUT "END\n";
close (FOUT);
#print "done. out put is in $fout\n";
sub helix_cont {
		my $count_win9=0;
		my $helix_value=0;my $g;my $t;
		my @limits=($i-3,$i-4);my $j;my $frac=0;
		my @limits2=($i+3,$i+4);my @dam;
loop31:		foreach $j (@limits2) {
			if ($j>$#seq) {
				next loop31;
				}
			$temp=$hProb[$i];
			$count_win9++;
			$t=$i+1;##push (@dam," $count_win9:$i");
			for ($g=$t;$g<=$j;$g++) {
				$temp=$temp*$hProb[$g];##push (@dam,$g)
				}
			$helix_value=$helix_value+$temp;;
			}
loop32:		foreach $j (@limits) {
			if ($j<0) {
				next loop32;
				}
			$count_win9++;
			$temp=$hProb[$i];
			$t=$i-1;##push (@dam," $count_win9:$i");
			for ($g=$t;$g>=$j;$g--) {
				$temp=$temp*$hProb[$g];##push (@dam,$g);
				}
			$helix_value=$helix_value+$temp;
			}
		#if ($count_win9=4) {
			#print $count_win9;print "@dam\n";
			#}
		$frac=$helix_value/$count_win9;
		return $frac;
		}
sub convert {
	my($ref) = shift;
        my(@e) = @{$ref};
	my $c;my $geusO;my $geusDP;my @e1;
	for ($c=0;$c<scalar@e;$c++) {
		if ($e[$c]>=0.05) {
			$e1[$c]=1;
			}
		else {
			$geusO=0.171*exp(-($e[$c]+0.035-0.00012)*($e[$c]+0.035-0.00012)/0.0011);
			$geusDP=0.128*exp(-($e[$c]+0.01-0.0026)*($e[$c]+0.01-0.0026)/0.0018);
			$e1[$c]=$geusDP/($geusDP+$geusO);
			print "$e[$c] $geusO $geusDP $e1[$c]\n";
			}
		}
	return @e1;
	}
