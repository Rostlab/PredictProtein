#!/usr/bin/perl -w
#this file will use the extracted data file to create NNprep files depending on the option selected
$data = $ARGV[0];
$length = $ARGV[1];
$option = $ARGV[2];
$dir = $ARGV[3];
@amino = ('A','R','N','D','C','Q','E','G','H','I','L','K','M','F','P','S','T','W','Y','V');
%prop = ();
%{$prop{"A"}} = (mass => 71, hyd => 50, charge => 50, cbeta => 0, surface => 0); 
%{$prop{"C"}} = (mass => 103, hyd => 100, charge => 50, cbeta => 0, surface => 100);
%{$prop{"D"}} = (mass => 115, hyd => 0, charge => 0, cbeta => 0, surface => 50);
%{$prop{"E"}} = (mass => 130, hyd => 0, charge => 0, cbeta => 0, surface => 100);
%{$prop{"F"}} = (mass => 147, hyd => 100, charge => 50, cbeta => 0, surface => 100);
%{$prop{"G"}} = (mass => 57, hyd => 50, charge => 50, cbeta => 0, surface => 0);
%{$prop{"H"}} = (mass => 137, hyd => 50, charge => 80, cbeta => 0, surface => 100);
%{$prop{"I"}} = (mass => 113, hyd => 100, charge => 50, cbeta => 100, surface => 100);
%{$prop{"K"}} = (mass => 128, hyd => 25, charge => 100, cbeta => 0, surface => 100);
%{$prop{"L"}} = (mass => 113, hyd => 100, charge => 50, cbeta => 0, surface => 100);
%{$prop{"M"}} = (mass => 131, hyd => 100, charge => 50, cbeta => 0, surface => 100);
%{$prop{"N"}} = (mass => 114, hyd => 0, charge => 50, cbeta => 0, surface => 50);
%{$prop{"P"}} = (mass => 97, hyd => 50, charge => 50, cbeta => 0, surface => 0);
%{$prop{"Q"}} = (mass => 128, hyd => 0, charge => 50, cbeta => 0, surface => 100);
%{$prop{"R"}} = (mass => 157, hyd => 25, charge => 100, cbeta => 0, surface => 100);
%{$prop{"S"}} = (mass => 87, hyd => 50, charge => 50, cbeta => 0, surface => 0);
%{$prop{"T"}} = (mass => 101, hyd => 50, charge => 50, cbeta => 100, surface => 50);
%{$prop{"V"}} = (mass => 99, hyd => 100, charge => 50, cbeta => 100, surface => 100);
%{$prop{"W"}} = (mass => 186, hyd => 100, charge => 50, cbeta => 0, surface => 100);
%{$prop{"Y"}} = (mass => 163, hyd => 50, charge => 50, cbeta => 0, surface => 100);

$prev_node = 0;
$file = $data;
#output file is $file.NNprep
$file =~ s/(.+\/)*//;
$file .= ".L$length.$option";
$file =~ s/Processed//;
print "Out file will be $file\n";
#EDITED TO ACCOMODATE FOR SIFT AND TRANSITIONS and May 3 (mass diff, hydrophobicity diff, charge diff, burried charge (mut org) for all)
#Input:
# 1 -- file name (eg Test for Test.out, Test.Pfam, Test.Rel
# 2 -- length of surrounding value
# 3 -- things to be extracted where:
#	pos 1 -- sequence (0 - no sequence, 1 -- sequence in 21 format, 2-- sequence in property format (8 node))
#	pos 2 -- profile (0 - no profile, 1 -- PSSM + gapless, 2 -- frequency + gapless, 3 -- change in freq for mutant only (gapless))
#	pos 3 -- rel accessability ( 0 -- no accessability, 1 -- acc + reliability, 2 -- 3 state by val acc + rel., 3 -- 9 state + rel acc and struct.)
#	pos 4 -- sec structure ( 0 -- no sec structure, 1 -- structure(network out) + reliability, 2 -- 3 state + rel)
#	pos 5 -- pfam (0 -- none, 1 -- domain + score, 2 -- domain + score + seed + match, 3 -all)
#	pos 6 -- psic (0 -- no psic, 1 -- psic final (0/50/100), 2 -- psic score for mut stretch + diff for mut only, 3 -- mut only + diff).
# 	pos 7 -- non-align prof (0 - no prof_n, 1 - diff between otH, otE, otL, and pAcc)
#	pos 8 -- 0 -- nothing, 1- sift only, 2 - transition only, 3 - sift and transition
#	pos 9 -- 0 -- nothing, 1 - bval
#	pos 10 -- 0 -- nothing, 1 - polyphen
$option =~ s/(\d)/$1 /g;
@option = split (/ /, $option);
$u = "";
$u_tot = 0;
#get the unknown representation
if ($option[0] == 1){
	foreach $i (1..20){
		$u .= "0\t";
	}
	$u .= "100\t";
	$u_tot += 21;
}
elsif ($option[0] == 2){
	foreach $i (1..8){
		$u .= "50\t";
	}
	$u_tot += 8;
}
if ($option[1] == 1){
	foreach $i (1..20){
		$u .= "100\t0\t";
	}
	$u .= "0\t0\t";
	$u_tot += 42;
}
elsif ($option[1] == 2){
	foreach $i (1..20){
		$u .= "5\t";
	}	
	$u .= "0\t0\t";
	$u_tot += 22;
}
elsif ($option[1] == 4){
	foreach $i (1..20){
		$u .= "0\t";
	}	
	$u_tot += 20;
}
if ($option[2] == 1){
	$u .= "50\t0\t";
	$u_tot +=2;
}
elsif ($option[2] == 2){
	$u .= "0\t0\t0\t0\t";
	$u_tot += 4;
}
elsif ($option[2] == 3){
	foreach $i (1..11){
		$u .= "0\t";
	}
	$u_tot += 11;
}
if ($option[3] > 0){
	$u .= "0\t0\t0\t0\t";
	$u_tot += 4;
}
#option 4 is only scored for the mutant, so doesn't need to be included for u
#option 5.2 is only one needed for u
if ($option[5] == 2){
	$u .= "100\t0\t0\t";
	$u_tot += 3;
}
#option 6 is also only for mutant evaluation, so doesn't need to be in u
#option 7 is only listed for mutants as well
#get flexibility option
if ($option[8] == 1){
	$u .= "50\t";
	$u_tot++;
}
print "u = $u_tot\n";


$cr = 0;
#open (IN, "/home/bromberg/work/PMD/AAprops.txt");
#@props = <IN>;
#close IN;
open (IN, $data) || die "Can't open $data\n";
$entry_count = 0;
open (OUT, ">$dir/$file");
$flag = 0;
$posi = 0;
$negi = 0;
$within_c = 0;
$node = 0;
$number = 0;
$skip = 0;
$pssm_a = $pssm_p = "";
LINE: foreach $line (<IN>){
	#if we are skipping these
	if (($within_c == 1) and ($skip > 0) and (!($line =~ /\>/))){
		$skip--;
		next LINE;
	}
	#get rid of trailer tab
	$line =~ s/\s*\n//;
	$line .= "\t\n";
	#if we are at new entry
	if ($line =~ /\>/){
		$skip = 0;
		$mut_vis = "";
		#if we need to print out U's at the end that were not printed
		if ($flag == 1){
			#find out how many times we need to print
			$dif = $end - $number;
			while ($dif > 0){
				print OUT "$u";
				#print $u;
				$dif--;
				$node += $u_tot;
			}
		}
		$prev_node = $node;
		#print out function for entries that were already processed
		if ($within_c > 0){
			$func = $func* 100;
			print OUT "$func\n";
		}
		#reset flag
		$flag = 0;
		$entry_count++;
		print OUT ">$entry_count\t";
		#get function
		$line =~ s/\>\s+(.+)\s+([A-Z])\s+(\d+)\s+([A-Z])\s+(.+)\t\n//;
		$org = $2;
		$pos = $3;
		$sub = $4;
		$func = $5;
		#print $name_gene."\n";
		if (($func =~ /[^0-9\-\.]/) or (!($func == 0))){
			$posi++;
			$func = 1;
		}
		else{
			$negi++;
			$func = 0;
		}
		#null within protein count
		$within_c = 1;
		$node = 0;
		$start = $pos - $length;
		$end = $pos + $length;
	}
	#if we are at first line, containing the number of the amino acid
	elsif ($within_c == 1){
		$mut_vis = &printSeq($option[0], $line);
		if ($mut_vis =~ /\d/){
			$within_c++;
		}
	}
	#this is the PSSM line for regular residues and the non-aligned prof line for mutant
	elsif ($within_c == 2){
		#for a regular residue do the PSSM stuff
		if ($mut_vis == 0){
			if ($option[1] == 1){
				$line =~ s/\n//;
				print OUT $line;
				$node += 40;
			}
			if (($option[1] =~ /1|3/) and ($number == $pos)){
				$pssm_p = &printPSSM ($option[1], $line, "pssm");
				print OUT $pssm_p;
			}
		}
		#for the mutant print the non-align difference
		elsif ($option[6] == 1){
			$line =~ s/\n//;
			print OUT $line;
			$node += 4;
		}	
		$within_c++;
	}
	#this contains the frequency for the regular residue and pfam data for the mutant 
	elsif ($within_c == 3){
		if ($mut_vis == 0){
			if ($option[1] == 2){
				$line =~ s/\n//;
				print OUT $line;
				$node += 20;
			}
			elsif ($option[1] == 4){
				$line =~ s/\n//;
				@q_a = split (/\s+/,$line);
				$i = 0;
				foreach $ac (@amino){
					if (($ac eq $org) or ($ac eq $sub)){
						print OUT "$q_a[$i]\t";
					}
					else{
						print OUT "0\t";
					}
					$i++;
				}
				$node += 20;
			}	
			if (($option[1] =~ /2|3/) and ($number == $pos)){
				$pssm_a = &printPSSM ($option[1], $line, "amino");
				print OUT $pssm_a;
			}
		}
		elsif ($option[4] == 3){
			#dom = 100; score = 6; begin= 0; end= 100; more dom = 0; seed= 50; match= 100; mut better 0;
			$line =~ s/\n//;
			print OUT $line;
			$node += 8;
		}
		elsif ($option[4] == 2){
			$line =~ s/\n//;
			$line =~ s/^(\d+\t\d+\t)\d+\t\d+\t\d+\t(\d+\t\d+\t).+/$1$2/;
			print OUT $line;
			$node += 4;
		}
		elsif ($option[4] == 1){
			$line =~ s/\n//;
			$line =~ s/^(\d+\t\d+\t).+/$1/;
			print OUT "$line";
			$node += 2;
		}
		$within_c++;
		
	}
	#this contains the gapless matches score and PSIC and SIFT ans Transition data in mutant
	elsif ($within_c == 4){
		if ($mut_vis == 0){
			if (($option[1] =~ /1|2/) or (($option[1] == 3) and ($number == $pos))){
				$line =~ s/\n//;
				print OUT "$line";
				$node += 2;
			}
			$within_c++;
		}
		else{
			#print for mutant ($bie contain stuff from original data)
			##including overal data for mutant mass, hydro, charge, cbeta, surface differences and buried charge)
			foreach $extra_k (keys %{$prop{$org}}){
				$diff_ex = sqrt (($prop{$org}{$extra_k} - $prop{$sub}{$extra_k}) *($prop{$org}{$extra_k} - $prop{$sub}{$extra_k}));
				#print "$diff_ex\t";
				print OUT "$diff_ex\t";
				$node++;
			}
			#print "s$hash{$sub}{"charge"}."\n";
			if (($bie == 0) and (!($prop{$sub}{"charge"} == 50))){
				#print  "100\t";
				print OUT "100\t";
			}
			else{
				#print "$bie 0\t";
				print OUT "0\t";
			}
			if (($hel eq 'H') and ($sub =~ /P/)){
				print OUT "100\t";
			}
			else{
				print OUT "0\t";
			} 
			$node+=2;
			#reset for after mutant data is done
			$within_c = 1;
			print "$line\n";
			$line =~ s/((\d+\t){4})((\d+\t){6})((\d+\t){2})((\d+\t){6})\n//;
			$psic = $1;
			$swiss = $3;
			$sift = $5;
			$transition = $7;		
			if ($option[5] == 2){
				print OUT "$psic";
				$node += 4;
			}
			if ($option[7] =~ /1|3/){
				#sift 
				print OUT "$sift";
				$node += 2;
			}
			if ($option[7] > 1){
				#transition
				print OUT "$transition";
				$node += 6;
			}
			#if ($option[9] == 1){
			#	print OUT "$poly";
			#	$node += 5;
			#}
			if ($option[10] == 1){
				print OUT "$swiss";
				$node += 6;
			}
		}
	}
	#this contains accessability and secondary structure info
	#RI_S    PREL    RI_A    Pbie     OtH     OtE     OtL
	elsif ($within_c == 5){
		#prel + reliability
		$t_line = $line;
		#print just the reliability of acessability an relative accessability
		#print the 3-node accesability and reliability
		$t = $line;
		$t =~ s/\n//;
		$t =~ s/^\d+\t\d+\t(\d+)\t(\d+)\t(\d+)\t(\d+)\t(\d+)//;
		$t = $1;
		$bie = $2;
		$h = $3;
		$e = $4;
		$l = $5;
		if (($h >= $e) and ($h >= $l)){
			$hel = 'H';
		}
		else{
			$hel = 'L';
		}
		
		if ($option[2] == 1){
			$line =~ s/\n//;
			$line =~ s/^\d+\t(\d+\t\d+\t).+/$1/;
			print OUT $line;
			$node += 2;
		}
		elsif ($option[2] == 2){
			#reliability of accessability
			print OUT $t."\t";
			if ($bie == 0){
				print OUT "100\t0\t0\t";
			}
			elsif ($bie == 40){
				print OUT "0\t100\t0\t";
			}
			elsif ($bie == 100){
				print OUT "0\t0\t100\t";
			}
			else{
				print "error at bie $bie\n";
				<STDIN>;
			} 
			$node += 4;
		}
		
		
		#print the 9-node accesability/structure and reliability for both
		elsif ($option[2] == 3){
			$line =~ s/\n//;
			@array = split (/\t/, $line);
			#print reliability
			print OUT "$array[0]\t$array[2]\t";
			$max = 0;
			$final = 0;
			foreach $i (4..6){
				if ($array[$i] > $max){
					$max = $array[$i];
					$final = $i;
				}
			}
			$max = "";
			foreach $i (4..6){
				if ($i == $final){
					$max .=  "100\t";
				}
				else{
					$max .= "0\t";
				}
			}
			if ($array[3] == 0){
				print OUT "0\t0\t0\t0\t0\t0\t$max";
			}
			elsif ($array[3] == 40){
				print OUT "0\t0\t0\t$max"."0\t0\t0\t";
			}
			elsif ($array[3] == 100){
				print OUT "$max"."0\t0\t0\t0\t0\t0\t";
			}
			$node += 11;
		}
		$line = $t_line;
		#print just the secondary structure reliability and 3 node net output format
		if ($option[3] == 1){
			$line =~ s/\n//;
			$line =~ s/^(\d+\t).+(\d+\t\d+\t\d+\t)$/$1$2/;
			print OUT $line;
			$node += 4;		
		}
		#print the structure in 3 node format + reliability
		elsif ($option[3] == 2){
			$line =~ s/\n//;
			@array = split (/\t/, $line);
			print OUT "$array[0]\t";
			$max = 0;
			$final = 0;
			foreach $i (4..6){
				if ($array[$i] > $max){
					$max = $array[$i];
					$final = $i;
				}
			}
			$max = "";
			foreach $i (4..6){
				if ($i == $final){
					$max .= "100\t";
				}
				else{
					$max .= "0\t";
				}
			}
			print OUT "$max";
			$node += 4;
		}
		$within_c++;
	}  
	#now dealing with psic 
	elsif ($within_c == 6){
		if ($option[5] == 2){
			$line =~ s/\n//;
			print OUT $line;
			$node += 3;
		}
		$within_c++;
	}
	#now dealing with flexibility
	elsif ($within_c == 7){
		if ($option[8] == 1){
			$line =~ s/\n//;
			print OUT $line;
			$node += 1;
		}
		$within_c = 1;
	}
	
}
#if U's are needed at the end
if ($flag == 1){
	#find out how many times we need to print
	$dif = $end - $number;
	while ($dif > 0){
		print OUT "$u";
		$dif--;
		$node += $u_tot;
	}
}

#print out function the last time
$func = $func* 100;
print OUT "$func\n";
print "$func\n";

close IN;
close OUT;		

open (SUM, ">$dir/$file.sum");
print SUM "Total nodes = $node\n";
print SUM "$posi positives, and $negi negatives, total ";
$posi = $posi + $negi;
print SUM "$posi entries\n";
close SUM;

sub printSeq{
	my $opt = shift @_;
	my $line = shift @_;
	#get the number of amino acid if the line is not mutant
	if (!($line =~ "Mut")){
		$line =~ s/^(\d+)\t//;
		$number = $1;
		#if we are not yet at start
		if ($number < $start){
			$skip = (7*($start-$number-1)) + 6;
			$flag = 1;
			return "";
		}
		#is we are already finished
		elsif ($number > $end){
			$skip = 1000;
			return "";
		}
		#if we need to print U's at start
		elsif (($flag == 0) and ($number > $start)){
			#find out how many times we need to print
			$dif = $number - $start;
			while ($dif > 0){
				print OUT $u;
				$dif--;
				$node += $u_tot;
			}
		}
		#flag indicating non-mutant residue
		$mut_vis = 0;
		$flag = 1;
		#if this is the end increment flag to avoid printing later
		if ($number == $end){
			$flag = 2;
		}
	}
	else{
		#flag indicating mutant residue
		$mut_vis = 1;
		$line =~ s/Mut\t//;
	}
	#if we need the residue data
	if ($option[0] > 0){
		$line =~ s/\n//;
		if ($option[0] == 1){
			print OUT $line;
			$node += 21;
		}
		elsif ($option[0] == 2){
			@sp = split (/\t/,$line);
			$cr = 0;
			foreach $s (@sp){
				if ($s == 100){
					$props[$cr] =~ s/[^0-9]//g;
					print OUT $props[$cr]."\t";
				}
				$cr++;
			}
			$node +=8;
		}
	}
	return $mut_vis;
}

sub printPSSM{
	my $opt = shift @_;
	my $line = shift @_;
	my $ind = shift @_;
	#get change at mutant
	@ps = split (/\t/, $line);
	$aa_c = 0;
	my $x;
	foreach $amino_acid (@amino){
		if ($amino_acid eq $org){
			if ($ind eq "pssm"){
				$wt_fs = $ps[$aa_c*2];
				$wt_f = $ps[$aa_c*2 + 1];
			}
			else{
				$wt_f = $ps[$aa_c];
			}			
		}
		elsif ($amino_acid eq $sub){
			if ($ind eq "pssm"){
				$mt_fs = $ps[$aa_c*2];
				$mt_f = $ps[$aa_c*2 + 1];
			}
			else{
				$mt_f = $ps[$aa_c];
			}
		}
		$aa_c++;
	}
	#print "$name_gene $org$pos$sub\n";
	if ($ind eq "amino"){
		if ($wt_f >= $mt_f){
			$x= "0";
		}
		else{
			$x= "100";
		}
		$wt_f = sqrt(($wt_f-$mt_f)*($wt_f-$mt_f));
		$node += 2;
		return "$x\t$wt_f\t";
	}
	else{
		if ($mt_fs == $wt_fs){
			$wt_f = sqrt(($wt_f-$mt_f)*($wt_f-$mt_f));
		}
		else{
			$wt_f = $wt_f + $mt_f;
		}
		$node++;
		return "$wt_f\t";
	}
}
