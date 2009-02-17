#!/usr/bin/perl -w

#this file will extract all data that may be necessary from prof, sequence alignment, and other files
#using the input file such as Data or Test, as a template
#this edited version applies to the newer files which contain lists of mutants

#this is the modified version of above for single runs of sequence


#first input is the file of concern
$fi = $ARGV[0];
$pwd = $ARGV[1];
$processed_dir = "$pwd/$ARGV[2]";
$gene = $ARGV[2];
@amino = ('A','R','N','D','C','Q','E','G','H','I','L','K','M','F','P','S','T','W','Y','V','U');
@art = 	(0.85786, 0.45676, 0.47306, 0.58022, 0.18036, 0.37722, 0.59724, 0.81155, 0.21639, 0.52944, 0.81156, 0.58717, 0.21109, 0.39946, 0.48178, 0.63047, 0.60835, 0.14256,0.36310, 0.68436);

#setup file hash
%files = ();
#setup list hash
%list = ();

#establish entry count
$g_c = 0;

#set up blosum hash
%seq = ();
#get the blosum file
$matrix = "$pwd/blosum62.txt";
&getBlosum();
&getPhat();
open (IN, $fi) || die "Can't open $fi\n";
open (ACCB, ">$processed_dir/procB") || die "Can't open $processed_dir/procB\n";
open (ACCI, ">$processed_dir/procI") || die "Can't open $processed_dir/procI\n";
open (ACCE, ">$processed_dir/procE") || die "Can't open $processed_dir/procE\n";
$list{"prof_a"} = $ARGV[3];
$list{"bval"} = $ARGV[4];
$list{"asci"} = $ARGV[5];
$list{"pfam"} = $ARGV[6];
$list{"prof_n"} = "$processed_dir/$gene.NArdbProf";
$list{"psic"} = "$processed_dir/$gene.out";
$list{"sift"} = "$processed_dir/$gene.SIFTprediction";
$list{"swiss"} = "$processed_dir/$gene.blastswiss";
#$list{"poly"} = "$processed_dir/$gene.poly";		

#check if these files exist
#before starting processing
foreach $key (keys %list){
	if (!(-e $list{$key})){
		if ($key eq "psic"){
			print $list{$key}." doesn't exist\n";
			$list{"psic"} = "standard";						
		}
		elsif ($key eq "sift"){
			$list{"sift"} = 2;
			$file[0] = 2;
		}
		else{
			print "$key\n";
			die "File $list{$key} doesn't exist\n";
		}
	}
	else{
		if ($key eq "pfam"){
			$pfam_f = `more $list{"pfam"}`;
			$pfam_f =~ s/(.*\n*)+Parsed for domains\://;
			@file = split (/Alignments/,$pfam_f);
        	}
		elsif ($key eq "sift"){
			$file[0] = 1;
		}
		else{
			open (FILE, $list{$key}) || die "$key of ".$list{$key}." doesn't exist\n";
			@file = <FILE>;
			close FILE;
		}
	}
	#header needs to be calculated
	if ($key  =~ /prof/){
		$files{$key}{"acc"}[0] = 0;
	}
	$files{$key}{"real"} = [@file];		
}
		
foreach $line (<IN>){
	if ($line =~ /\>/){
		close OUT;
		#increase entry count
		$g_c++;
		$line =~ s/\>|\n//g;
		$entry = $line;
		$name = $line;
		$name =~ s/ (0|1)//;
		$entry =~ s/^(.+)\.([A-Z])(\d+)([A-Z])(\s.*)*//;
		$org = $2;
		$pos = $3;
		$sub = $4;
		$func = $5;
		print "$org $pos $sub $func\n";
		if (!$func){
			$func = 0;
		}
		$proc_data = "$gene.$org$pos$sub";
		$list{"prof"} = "$processed_dir/$gene.$org$pos$sub.rdbProf";
		if (!(-e $list{"prof"})){
			print "prof\n";
			die "File $list{\"prof\"} doesn't exist\n";
		}
		else{
			open (FILE, $list{"prof"}) || die "prof of ".$list{"prof"}." doesn't exist\n";
			@file = <FILE>;
			close FILE;
			$files{"prof"}{$proc_data}{"acc"}[0] = 0;
		}
		$files{"prof"}{$proc_data}{"real"} = [@file];		
	}
	elsif ($line =~ /[A-Z]/){
		#get rid of x's
		$line =~ s/X|x/U/g;
		#get rid of anything that is not a letter
		$line =~ s/[^A-Z]//g;
		
		#split the sequence into an array
		$line =~ s/([A-Z])/$1 /g;
		#print $line."\n";
		$kept_seq = $line;
		if ($pos <= 5){
			$temp_l = $pos-1;
			$kept_seq =~ s/(([A-Z] ){$temp_l})$sub/$1$org/;
		}
		@seq = split (/ /, $line);
		#get the length of sequence
		$length = @seq;
		
		#check if the name corresponds to the actual mutant
		if (!($seq[$pos-1] eq $sub)){
			die "Mutant in sequence $name $seq[$pos-1] is not $sub\n";
		}
		open (OUT, ">$processed_dir/$proc_data") || die "Can't open $processed_dir/$proc_data\n";
		print OUT "> $gene $org $pos $sub $func\n";
		
		#if we have at least 10 residues before the mutant
		#e.g. the mutant is at least in position 11
		if ($pos - 4 >= 0){
			#to account for sstarting the array at 0
			$start = $pos - 4;
		}
		#else, we don't have enough amino acids before the mutant
		#so we start at 0
		else{
			#to account for sstarting the array at 0
			$start = 0;
		}
		
		#now check if there are enough amino acids at the end of sequence
		#e.g. the mutant is in the position $length-10 or further
		if ($pos + 3 <= $length){
			#to account for starting the array at 0
			$end = $pos + 2;
		}
		#else end at the end
		else{
			#to account for starting the array at 0
			$end = $length-1;
		}
		$flag = 0;
				
		while (($start <= $end) or ($flag == 1)){
			if ($start == $pos-1){
				$aa = $org;
				$flag = 1;
				$start++;
				print OUT "$start\t";
			} 
			elsif ($flag == 1){
				$aa = $sub;
				if ($pos == 2){
					$org_stretch[0] = "U".$seq[$start-2].$org;
					$org_stretch[1] = $seq[$start-2].$org.$seq[$start];
					$org_stretch[2] = $org.$seq[$start].$seq[$start+1];
					$mut_stretch[0] = "U".$seq[$start-2].$sub;
					$mut_stretch[1] = $seq[$start-2].$sub.$seq[$start];
					$mut_stretch[2] = $sub.$seq[$start].$seq[$start+1];
				}
				elsif ($pos == 1){
					$org_stretch[0] = "UU".$org;
					$org_stretch[1] = "U".$org.$seq[$start];
					$org_stretch[2] = $org.$seq[$start].$seq[$start+1];
					$mut_stretch[0] = "UU".$sub;
					$mut_stretch[1] = "U".$sub.$seq[$start];
					$mut_stretch[2] = $sub.$seq[$start].$seq[$start+1];
				}
				elsif ($pos == $length){
					$org_stretch[0] = $seq[$start-3].$seq[$start-2].$org;
					$org_stretch[1] = $seq[$start-2].$org."U";
					$org_stretch[2] = $org."UU";
					$mut_stretch[0] = $seq[$start-3].$seq[$start-2].$sub;
					$mut_stretch[1] = $seq[$start-2].$sub."U";
					$mut_stretch[2] = $sub."UU";
				}
				elsif ($pos == $length -1){
					$org_stretch[0] = $seq[$start-3].$seq[$start-2].$org;
					$org_stretch[1] = $seq[$start-2].$org.$seq[$start];
					$org_stretch[2] = $org."UU";
					$mut_stretch[0] = $seq[$start-3].$seq[$start-2].$sub;
					$mut_stretch[1] = $seq[$start-2].$sub.$seq[$start];
					$mut_stretch[2] = $sub."UU";
				}
				else{
					$org_stretch[0] = $seq[$start-3].$seq[$start-2].$org;
					$org_stretch[1] = $seq[$start-2].$org.$seq[$start];
					$org_stretch[2] = $org.$seq[$start].$seq[$start+1];
					$mut_stretch[0] = $seq[$start-3].$seq[$start-2].$sub;
					$mut_stretch[1] = $seq[$start-2].$sub.$seq[$start];
					$mut_stretch[2] = $sub.$seq[$start].$seq[$start+1];
				}
				$flag = 2;
				print OUT "Mut\t";
			}
			else{
				$aa = $seq[$start];
				$start++;
				$flag = 0;
				print OUT "$start\t";
			}
			#print the residue in 21 node format
			$ok = &printRes();
			#print "h2\n";

			if (!$ok){
				die "failed printing amino acid\n";
			}
			#for all other than mutant
			if ($flag < 2){
				&extractASCI();
				&extractProf_A();
				&extractPsic();
				&extractBval();
			}
			#for mutant only and org residues
			if ($flag > 0){
				&extractProf_N();
			}
			#for mutant only
			if ($flag == 2){
				&extractPfam();
				&extractPsic();
				&extractSwiss();
				&extractSift();
				#&extractPoly();
				
				#get the transitions
				$trans = 0;
				while ($trans <= 2){
					$org_stretch = $org_stretch[$trans];
					$org_stretch = `more $pwd/TransitionsBIG.txt | grep $org_stretch`;
					$org_stretch =~ s/[^\.0-9]//g;
					$mut_stretch = $mut_stretch[$trans];
					$mut_stretch = `more $pwd/TransitionsBIG.txt | grep $mut_stretch`;
					$mut_stretch =~ s/[^\.0-9]//g;
					$dif = 10*($org_stretch - $mut_stretch);
					if ($dif =~ /\-/){
						$dif =~ s/\-//;
						print OUT "\t0";
					}
					else{
						print OUT "\t100";
					}
					$dif = int($dif);
					print OUT "\t$dif";
					$trans++;
				}
				print OUT "\n";
			}	
		}
	}
}

sub extractSwiss{
	my @file = @{$files{"swiss"}{"real"}};
	my $file = "@file";
	my ($t, $temp, $name_k, $e, $s, $en, $position, $f);
	#print "gene is $gene\n";
	$f = 0;
	if ($file =~ /\|$gene(\||\s+)/){
		#print "$file\n";
		#<STDIN>;
		#print "choosing itself\n";
		$file =~ s/\|$gene.*\s+(0\.0|\d*e\-\d+)\s*\n//;
		$temp = $1;
		$name_k = $gene;
		$f = 1;
		if (!$temp){
			print "no temp $file\n";
			#<STDIN>;
			$f = 0;
		}
		$position = $start;
	}
	if ($f == 0){
		#print "$file\n";
		if ($file =~ /No hits found/){
        	        print " there are no good scores\n";
        	        print OUT "0\t0\t0\t0\t0\t0\t";
        	        return;
	        }

		$file =~ s/[^\>]+\>([^\s\|]+\|)+([^\s]+)\s+([^\>]+)(\>|Database\:)//;
		$name_k = $2;
		$temp = $3;
		$file =~ s/\|$name_k.+\s+(0\.0|\d*e\-\d+)\s*\n//;
		$e = $1;
		if (!$e){
			print "$file e = $e\n";
			print " there are no good scores\n";
			print OUT "0\t0\t0\t0\t0\t0\t";
			return;
		}
		#print $file."\n";
		#<STDIN>;
		@file = split (/Query/,$temp);
		foreach $file (@file){
			if (!($file =~ /Sbjct\:/)){
				next;
			}
			$file =~ s/\:\s+(\d+)\s+([^\d]+)\s+(\d+)[^\:]+//;
			$s = $1;
			$t = $2;
			$en = $3;
			if (($start >= $s) and ($start <= $en)){
				$f = 1;
				$s--;
				$t =~ s/[^A-Z\-]//g;
				$t =~ s/(.)/$1 /g;
				@q = split (/ /, $t);
				$file =~ s/\:\s+(\d+)//;
				$en = $1 - 1;
				$file =~ s/[^A-Z\-]//g;
				$file =~ s/(.)/$1 /g;
				#print "s en startq = $s\n q=$t \nstarts = $en\n f=$file\n";
				@s = split (/ /, $file);
				$q = 0;
				foreach $t (@s){
				#print "$q = $q[$q]\n";
					if ($q[$q] =~ /[A-Z]/){
						$s++;
					}
					if ($s[$q] =~ /[A-Z]/){
						$en++;
					}
					#print "$q[$q] = $s[$q]\n";
					if (($s == $start) and (!($s[$q] =~ /[A-Z]/))){
						print "alignment is gapped\n";
						print OUT "0\t0\t0\t0\t0\t0\t";
						return;
					}
					elsif ($s == $start){
						$position = $en;
						last;
					}
					#print "s $s\n";
					$q++;	
				}
			} 
		}
	}
	if ($f == 0){
		print "there is no good alignment\n";
		print OUT "0\t0\t0\t0\t0\t0\t";
		return;
	}
	print "choosing $name_k $position\n";
	if ((!(-e "$processed_dir/$gene.swiss")) and ($name_k =~ /\_/)){
		$e = $name_k;
		$e =~ s/\_(\w)//;
		$e = $1;
		$e =~ tr/A-Z/a-z/;
		$en = $name_k;
		$en =~ tr/A-Z/a-z/;
		print "/data/swissprot/current/$e/$en\n";
		if (-e "/data/swissprot/current/$e/$en"){
			$temp = `more /data/swissprot/current/$e/$en`;
			@temp = split (/\n/, $temp);
			foreach $line (@temp){
				open (SWISS, ">>$processed_dir/$gene.swiss");
				if ($line =~ /FT\s+(DISULFID|SE_CYS|TRANSMEM|PROPEP|MOD_RES|SIGNAL|MUTAGEN|CONFLICT|VARIANT|BINDING|ACT_SITE|SITE|LIPID|METAL|CARBOHYD|DNA_BIND|ZN_FING|CA_BIND|NP_BIND)/){
					$line =~ s/FT\s+//;
					if ($line =~ /TRANSMEM|PROPEP|MOD_RES|SIGNAL|MUTAGEN|CONFLICT|VARIANT|BINDING|ACT_SITE|SITE|LIPID|METAL|CARBOHYD|DNA_BIND|ZN_FING|CA_BIND|NP_BIND/){
					#	print $line."\n";
						$line =~ s/(TRANSMEM|PROPEP|MOD_RES|SIGNAL|MUTAGEN|CONFLICT|VARIANT|BINDING|ACT_SITE|SITE|LIPID|METAL|CARBOHYD|DNA_BIND|ZN_FING|CA_BIND|NP_BIND)\s+(\?|\>|\<)*(\d+)\s+(\?|\<|\>)*(\d+)//;
						$e = $1;
						$s = $3;
						$en = $5;
						#print $line."\n";
						if (!$s or !$en){
							print "no actual start or end for $line\n";
							next;
						}
						foreach $s ($s..$en){
							print SWISS "$e $s\n";
						}
					}
					elsif($line =~ /DISULFID|SE_CYS/){
						$line =~ s/(DISULFID|SE_CYS)\s+\?*(\d+)\s+\?*(\d+)//;
						$line = $1;
						$s = $2;
						$en = $3;
						print SWISS "$line $s\n$line $en\n";
					}					
				}
				close SWISS;
			}
		}
		else{
			print "There is no swiss file\n";
			print OUT "0\t0\t0\t0\t0\t0\t";
			return;
		}
	}
	$temp = `more $processed_dir/$gene.swiss`;
	#print "pos = $start\n";
	if ($temp =~ /([A-Z]+\s+$position\s+)/){
		$temp =~ s/([A-Z]+(\_[A-Z]+)*\s+$position\s+)//;
		$temp = $1;
		#print $temp."\n";
		if ($temp =~ /BINDING|ACT_SITE|SITE|LIPID|METAL|CARBOHYD|DNA_BIND|ZN_FING|CA_BIND|NP_BIND/){
			print OUT "100\t";
			print "act\t";
		}
		else{
			print OUT "0\t";
		}
		if ($temp =~ /DISULFID|SE_CYS/){
			print OUT "100\t";
			print "bond\t";
		}
		else{
			print OUT "0\t";
		}
		if ($temp =~ /MOD_RES|PROPEP|SIGNAL/){
			print OUT "100\t";
			print "signal\t";
		}
		else{
			print OUT "0\t";
		}
		if ($temp =~ /TRANSMEM/){
			print OUT "100\t";
			print OUT $phat{$org}{$sub}."\t";
			print "trans\t";
		}
		else{
			print OUT "0\t0\t";
		}
		if ($temp =~ /MUTAGEN|CONFLICT|VARIANT/){
			print OUT "100\t";
			print "variant\t";
		}
		else{
			print OUT "0\t";
		}
	}
	else{
		print "There is no annotation for this position\n";
		print OUT "0\t0\t0\t0\t0\t0\t";
		return;
	}
	return;
}

sub extractPsic {
	my $psic_w = 0;
	my (@set, $seqs, $p, $pst, $line, $c);
	if ($aa eq 'U'){
		print OUT "100\t0\t0\n";
		return;
	}
	if ($list{"psic"} eq "standard"){
		@set = @art;
		$seqs = 0;
	}
	else{
		$line = $files{"psic"}{"real"}[$start];
		$line =~ s/^(\d+) //;
		$pst = $1;
		$line =~ s/\s+(\d+)\n//;
		$seqs = $1;
		#here evrything is moved 1 residue
		$p = $start-1;
		#if the line doesn't contain the right count
		if (!($pst == $p)){
			die "Wrong line - s $start p $pst l $line (line # $p)\n";
		}
		@set = split (/ /, $line);
	}
	$c = 0;
	#get the psic score
	while (!($amino[$c] eq $aa)){
		$c++;
	}
	#if it contains exponents, than the psic score is too small == 0
	#if the residue is U, then the psic score is 0
	if ($set[$c] =~ /e/){
		$set[$c] = 0;
	}
	#if we are talking about mutant position in both wild type and mutant
	if ($flag == 1){
		$psic_w = $set[$c];
	}
	elsif ($flag == 2){
		$psic_w = $set[$c] - $psic_w;
		if ($psic_w < 0){
			$psic_w = 0 - $psic_w;
		}
	}
	#if the score is negative than first node is 0
	if ($set[$c] < 0){
		print OUT "0\t";
		$set[$c] = 0 - $set[$c];
	}
	#else its 100
	else{
		print OUT "100\t";
	}
	$set[$c] =~ s/\+|\-//g;
	print OUT round($set[$c]*25);
	print OUT "\t$seqs";
	if ($flag == 2){
		print OUT "\t".round($psic_w*25)."\t";
	}
	else{
		print OUT "\n";
	}
	return;
}
close ACCE;
close ACCB;
close ACCI;
sub extractBval{
	my $file = $files{"bval"}{"real"}[$start];
	#print $file."\n";
	$file =~ s/X/U/g;
	$file =~ tr/a-z/A-Z/;
	if ($file =~ /\s+(\-*\d+)[^0-9A-Za-z\-]*$/){
		$file = $1;
		$file = int((100 + $file)/2);
	}
	else{
		die "Wrong line - $file in bval . Should have $aa in position $start\n";
	}
	print OUT "$file\n";
	return;
}

	

sub printRes{
	my $aa = $aa;
	my $amino;
	my $ok = 0;
	#print "a = $aa\n";
	foreach $amino (@amino){

		if ($amino eq $aa){
			print OUT "100\t";
			$ok = 1;
		}
		else{
			print OUT "0\t";
		}
	}
	print OUT "\n";
	return $ok;
}
sub extractSift{
	my $pos = $pos;
	my $org = $org;
	my $sub = $sub;
	my $file = $files{"sift"}{"real"}[0];
	
	if ($file eq "2"){
		print OUT "50\t50";
	}
	else{
		$file = $list{"sift"};
		my $line = `more $file | grep $org$pos$sub`;
		#print $line."\n";
		#if the extraction wasn't run
		if (!($line)){
			print OUT "50\t50";
		}
		elsif ($line =~ /TOLERATED/){
			print OUT "0\t";
			$line =~ s/TOLERATED\s+(\d+\.*\d*)\s+//;
			my $score = $1;
			$score = $score*100;
			print OUT "$score";
		}
		elsif ($line =~ /DELETERIOUS/){
			print OUT "100\t";
                        $line =~ s/DELETERIOUS\s+(\d+\.*\d*)\s+//;
                        my $score = $1;
                        $score = $score*100;
                        print OUT "$score";

		}
		elsif ($line =~ /NOT SCORED/){
			print OUT "50\t50";
		}
	}
	#print OUT "\n";
	return;
}
#sub extractPoly{
#	my @file = @{$files{"poly"}{"real"}};
	#print $file."\n";
#	my $line = "@file";
	#print $line."\n";
#	$line =~ s/(id\s+proven\s+[^\s]+\s+$pos\s+$org\s+$sub.+)\n//;
#	$line = $1;
	#print $line."\n";
	#print OUT "b=";
#	if ($line =~ /benign/){
#		print OUT "0\t100\t";
#	}
#	elsif ($line =~ /damaging/){
#		print OUT "100\t0\t";
#	}
#	else {
#		print OUT "50\t50\t";
#	}
	#print OUT "a=";
#	if ($line =~ /alignment/){
#		print OUT "100\t0\t0";
#	}
#	elsif ($line =~ /structure/){
#		print OUT "0\t100\t0";
#	}
#	elsif ($line =~ /sequence annotation/){
#		print OUT "0\t0\t100";
#	}
#	else{
#		print OUT "0\t0\t0";
#		print "using default for Poly: $gene\n";
#		#<STDIN>;
#	}	
#	return;
#}	

sub extractASCI {
	my $line = $files{"asci"}{"real"}[$start+2];
	#print "\n $line\n";
	$line =~ s/X/U/;
	if (!($line =~ /\s*$start\s+$aa\s+/)){
		die "Wrong line - $line in asci . Should have $aa in position $start\n";
	}
	$line =~ s/\s*$start\s+$aa\s+//;
	my @asc = split (/\s+/, $line);
	my $c = 0;
	#print PSSM , 2 nodes each 0 for negative, 100 for positive, the score is *5
	while ($c <= 19){
		if ($asc[$c] >= 0){
			print OUT "100\t";
		}
		else{
			print OUT "0\t";
			$asc[$c] = 0 - $asc[$c];
		}
		$asc[$c] = $asc[$c]*5;
		print OUT "$asc[$c]\t";
		
		$c++;
	}
	print OUT "\n";
	#print "PROFILE, 1 percentage node for each;
	while ($c <= 39){
		if (!($asc[$c] =~ /\d/)){
			print "ASCI file missing stuff $line\n";
			exit;		       
		}
		print OUT "$asc[$c]\t";
		$c++;
	}
	print OUT "\n";
	#print gapless matches and information per position
	if ($asc[$c] < 0){
		print OUT "0\t";
	}
	else{
		$asc[$c] = int($asc[$c]*50);
		print OUT $asc[$c]."\t";
	}
	$c++;
	if ($asc[$c] < 0){
		print OUT "0\t";
	}
	else{
		$asc[$c] = int($asc[$c]*50);
		print OUT $asc[$c]."\t";
	}
	print OUT "\n";
	return;
}

sub extractProf_A{
	my ($prof_start, $prof_line, @pro, $c, $ent, $first_line, $k, $seq_flag, $j);
	#if the start is at 0, then we don't have the header info
	if ($files{"prof_a"}{"acc"}[0] == 0){
		$prof_start = 0;
		#get header first to account for differences in way prof creates output
		while (!($files{"prof_a"}{"real"}[$prof_start] =~ /^No\s+AA/)){
			if ($files{"prof_a"}{"real"}[$prof_start] =~ /\#\s+VALUE\s+PROT_NALI :\s+(\d+)/){
				$files{"prof_a"}{"real"}[$prof_start] =~ s/\#\s+VALUE\s+PROT_NALI :\s+(\d+)//;
				$files{"prof_a"}{"acc"}[2] = $1;
				if ($files{"prof_a"}{"acc"}[2] > 100){
					$files{"prof_a"}{"acc"}[2] = 100;
				}
				elsif (!($files{"prof_a"}{"acc"}[2] =~ /\d/)){
					$files{"prof_a"}{"acc"}[2] = 0;
				}
			}	
			$prof_start++;
		}
		$k = 1;
		$j = "";
		while ($k <= 5){
			$first_line = $files{"prof_a"}{"real"}[$prof_start+$k];
			$first_line =~ s/\d+\s+([A-Z])\s+//;
			$first_line = $1;
			$j .= "$first_line ";
			$k++;
		}
		#j now contains the start of prof
		$j =~ s/X/U/g;
		$seq_flag = 0;
		$files{"prof_a"}{"acc"}[0] = $prof_start;
		my @head = split (/\s+/, $files{"prof_a"}{"real"}[$prof_start]);
		$files{"prof_a"}{"acc"}[1] = [@head];
		
	#	print $j."\n$kept_seq";
		OUTW: while (!($kept_seq =~ /^([A-Z] ){$seq_flag}$j/)){
			$seq_flag++;
			if ($seq_flag > @seq){
				print "Start of aligned file $gene not found. In prof - $j\n";
				last OUTW;
			}
		}		
		$files{"prof_a"}{"acc"}[2] = $seq_flag;
	}
	else{
		$prof_start = $files{"prof_a"}{"acc"}[0];
		$seq_flag = $files{"prof_a"}{"acc"}[2];
	}
	#print "start with $seq_flag\n";
	
	$prof_line = $files{"prof_a"}{"real"}[$start+$prof_start-$seq_flag];
	$prof_line =~ s/X/U/g;	
	@pro = split (/\s+/, $prof_line);
	$c = 0;	
	foreach $ent (@{$files{"prof_a"}{"acc"}[1]}){
		#checks ent and c increment together
		#so the header should be what is expected
		if (($ent =~ /AA/) and (!($pro[$c] =~ /$aa/)) and (!($pro[$c] eq 'U'))){
			die "Wrong aa in aligned file $prof_line. Should be $aa\n $seq\n";
		}
		#in printing reliability of structure and accessability, multiply by 10
		elsif ($ent =~ /RI_S|RI_A/){
			$pro[$c] = $pro[$c] * 10;
			print OUT $pro[$c]."\t";
		}
		#in printing relative accessability and structure just print
		elsif ($ent =~ /PREL|OtH|OtE|OtL/){
				print OUT $pro[$c]."\t";
		}
		#in printing three state accessability, print 0/40/100 (where 0 is buried)
		elsif ($ent =~ /Pbie/){
			if ($pro[$c] =~ /b/){
				print OUT "0\t";
				if ($flag > 0){
					print ACCB "$gene.$org$pos$sub $func\n";
				}
			}
			elsif ($pro[$c] =~ /i/){
				print OUT "40\t";
				if ($flag > 0){
					print ACCI "$gene.$org$pos$sub $func\n";
				}
			}
			elsif ($pro[$c] =~ /e/){
				print OUT "100\t";
				if ($flag > 0){
					print ACCE "$gene.$org$pos$sub $func\n";
				}
			}
			else{
				die "Something wrong in Pbie extraction\n";
			}
		}
		$c++;
	}		
	print OUT "\n";
	return;
}

sub extractProf_N{
	my ($prof_start, $prof_line, @pro, $c, $ent, $i, $temp);
	#if the start is at 0, then we don't have the header info
	if ($flag == 1){
		$temp = "prof_n";
		%temp = %{$files{$temp}};
	}
	elsif ($flag == 2){
		$temp = "prof";
		%temp = %{$files{$temp}{$proc_data}};
	}
	else{
		die "Can't do Unaligned prof processing for anything other than mutants\n";
	}
	if ($temp{"acc"}[0] == 0){
		$prof_start = 0;
		#get header first to account for differences in way prof creates output
		while (!($temp{"real"}[$prof_start] =~ /^No\s+AA/)){	
			$prof_start++;
		}	
		$temp{"acc"}[0] = $prof_start;
		my @head = split (/\s+/, $temp{"real"}[$prof_start]);
		$temp{"acc"}[1] = [@head];
	}
	else{
		$prof_start = $temp{"acc"}[0];
	}
	
	$prof_line = $temp{"real"}[$start+$prof_start];
	$prof_line =~ s/X/U/g;	
	@pro = split (/\s+/, $prof_line);
	$c = 0;	
	$i = 0;
	foreach $ent (@{$temp{"acc"}[1]}){
		#checks ent and c increment together
		#so the header should be what is expected
		if (($ent =~ /No/) and (!($pro[$c] == $start))){
			die "Wrong count_a $start in $prof_line\n";
		}
		elsif (($ent =~ /AA/) and (!($pro[$c] =~ /$aa/)) and (!($pro[$c] eq 'U'))){
			die "Wrong aa in aligned file $prof_line. Should be $aa\n $seq\n";
		}
		#get structure and actual accessability from non-aligned prof for difference purposes only 
		elsif ($ent =~ /OtH|OtE|OtL|PACC/){
			if ($flag == 1){
				$ot_w[$i] = $pro[$c];
			}
			else{
				my $n_mut = sqrt(($ot_w[$i] - $pro[$c])*($ot_w[$i]-$pro[$c]));
				print OUT $n_mut."\t";
			}
			$i++;
		}
		$c++;
	}
	if ($flag == 2){
		print OUT "\n";
	}		
	return;
}		
		
sub extractPfam{
	#outline contains the score and name information for matches
	my $outline = $files{"pfam"}{"real"}[0];
	#actual contains the data itself
	my $actual = $files{"pfam"}{"real"}[1];
	my @outline = split (/\n/, $outline);
	$outline = "";
	my %hash = ();	
	my ($entry, $c, $score, $domain, @v, $s, $e, $part, @pf, $space, @seqs, @dom, @med);
	#for each of the scores in the outline
	foreach $entry (@outline){
		#if the part has a domain name
		if ($entry =~ /PF/){
			@entry = split (/\s+/, $entry);
			#if the score of the domain is less than 10e-3
			if (($entry[9] =~ /e/) or ($entry[9] <= .001)){
				$score = $entry[9];
				$domain = $entry[0];
				#if the stretch of the domain includes mutant position
				if (($entry[3] >= $pos) and ($entry[2] <= $pos)){
					#get the e-values 10 value
					if ($score =~ /e/){
						$score =~ s/.+e\-//;
					}
					elsif ($score == 0){
						$score = 1000;
					}
					else{
						$c = 0;
						while ($score < 1){
							$score = $score * 10;
							$c++;
						}
						$score = $c;
					}
					#whether an end or a start is at most 10 amino acids away
					if ($pos+10 <= $entry[3]){
						$hash{$domain}{"fi"} = 0;
					}
					else{
						$hash{$domain}{"fi"} = 100;
					}
					if ($pos-10 >= $entry[2]){		
						$hash{$domain}{"si"} = 0;
					}
					else{
						$hash{$domain}{"si"} = 100;
					}
					$hash{$domain}{"score"} = $score;
				}
			}
		}
	}
	#sort the domains by highest to lowest score, but only use highest 
	my @arr = sort {$hash{$b}{"score"} <=> $hash{$a}{"score"}} keys %hash;
	#print "array = @arr\n";
	#if after processing above, there are no domains left return
	#1-no domain matched
	#2-score is unimportant
	#3/4-nothing is known about beginning/ending of domain within 10 amino acids
	#5 - there are no more domains
	#6 - not part of seed
	#7 - not a match
	#8 - mutant is the same
	if (@arr == 0){
		print OUT "0\t0\t50\t50\t0\t0\t0\t50\n";
		return;
	}
	#otherwise, continue processing	
	$actual =~ s/ of top-scoring domains\:\n//;
	$actual =~ s/\n\/\///;
	my @actual = split (/\nPF/, $actual);
	#foreach of the domains in actual
	foreach $actual (@actual){
		if ($actual =~ /\w/){
			if (!($actual =~ /^PF/)){
				$actual = "PF".$actual;
			}
			$actual =~ s/^(PF[^ ]+)\:.+\n//;
			$domain = $1;
			#get the domain that has a high score into the hash
			if ($domain eq $arr[0]){
				$hash{$domain}{"text"} .= "ac = $actual";
			}
		}
	}
	$domain = $arr[0];
	$score = $hash{$domain}{"score"};
	#print that residue is part of a domain
	print OUT "100\t";
	#print the log of the score divided by 3
	$score = int ($score/3);
	if ($score > 100){
		$score = 100;
	}
	print OUT "$score\t";
	#is the start of the domain >10 residues avay from the position?
	print OUT $hash{$domain}{"si"}."\t";
	#id the end of the domain >10 residues away from the position?
	print OUT $hash{$domain}{"fi"}."\t";
	#is it a part ofother domains?
	if (@arr > 1){
		print OUT "100\t";
	}
	else{
		print OUT "0\t";
	}
	#get the actual text of alignment(s)
	$actual = $hash{$domain}{"text"};
	#each of alignment(s) is in the array @v
	@v = split (/ac \= /,$actual);
	foreach $actual (@v){
		if (!($actual =~ /\w/)){
			next;
		}
		@actual = split (/[^ \d\w\+\-\*\.\<]\n/,$actual);
		#@actual now contains the alignment parts
		foreach $part (@actual){
			#if the domain is much longer then the match, the match doesn't contain
			#any letters or numbering
			if (!($part =~ /[A-Za-z\.0-9\_]+\s+(\d+)\s+([A-Za-z\-]+)\s+(\d+)/)){
				next;
			}
			$part =~ s/[A-Za-z\.0-9\_]+\s+(\d+)\s+([A-Za-z\-]+)\s+(\d+)/$2/;
			$s = $1;
			$e = $3;
			#if the alignment contains the mutant
			if (($pos >= $s) and ($pos <= $e)){
				$part =~ s/\s+CS\s+.+\n//;
				$part =~ s/\s+RF\s+(x|\s)*\n//g;
				#@pf contains the three lines of alignment
				#0 -- seed
				#1 -- alignment
				#2 -- query
				@pf = split (/\n/,$part);
				$pf[0] =~ s/^([^A-Za-z\.]+)([A-Za-z\.])/$2/;
				#space is the actual number of spaces
				$space = $1;
				$space =~ s/[^ \-\*\>]//g;
				$pf[0] =~ s/[^A-Za-z\.]//g;
				$pf[0] =~ s/(.)/$1 /g;
				@dom = split (/ /, $pf[0]);
				$space = length($space);
				$pf[1] =~ s/([^A-Z\+\.a-z]){$space}//;
				$pf[1] =~ s/([ A-Za-z\+\.])/$1\%/g;
				@med = split (/\%/, $pf[1]);
				$pf[2] =~ s/[^A-Za-z\-]//g;
				$pf[2] =~ s/(.)/$1 /g;
				@seqs = split (/ /, $pf[2]);
				$i = 0;
				while ($i < @seq){
					if ($s + $i == $pos){
						#is it part of seed
						#NO
						if ($dom[$i] =~ /\./){
							print OUT "0\t";
						}
						#MAYBE
						elsif ($dom[$i] =~ /[a-z]/){
							print OUT "50\t";
						}
						#YES
						elsif ($dom[$i] =~ /[A-Z]/){
							print OUT "100\t";
						}
						else{
							print "wrong $dom[$i]\n";
							<STDIN>;
						}
							
						#is it a match
						#NO
						if ($med[$i] =~ / /){
							print OUT "0\t";
						}
						#SORT OF
						elsif ($med[$i] =~ /\+/){
							print OUT "50\t";
						}
						#YES
						elsif ($med[$i] =~ /[A-Za-z]/){
							print OUT "100\t";
						}
						else{
							print "wrong \"$med[$i]\"\n";
							print "@dom\n@med\n@seqs";
							<STDIN>;
						}
						
						$dom[$i] =~ tr/a-z/A-Z/;
						#is mutant a better match ?
						#SAME
						if ($dom[$i] =~ /\./){
							print OUT "50\t";
						}
						#WORSE
						elsif ($med[$i] =~ /[A-Za-z]/){
							print OUT "0\t";
						}
						else{
							#WORSE
							if ($seqs{$dom[$i]}{$org} > $seqs{$dom[$i]}{$sub}){
								print OUT "0\t";
							}
							#BETTER
							elsif ($seqs{$dom[$i]}{$org} < $seqs{$dom[$i]}{$sub}){
								print OUT "100\t";
							}
							#SAME
							else{
								print OUT "50\t";
							}
						}
						print OUT "\n";
						return;
					}
					$i++;
				}
				#if we got to this point print error
				die "Something wrong with PFAM extraction\n";
			}		
		}
	}
}

sub getBlosum{
	my ($amino, $i, @l, $aa, $matr);
	open (MAT, $matrix);
	foreach $matr (<MAT>){
		if ($matr =~ /\d/){
			$matr =~ s/([A-Z])//;
			$amino = $1;
			$i = 0;
			while ($i < @amino){
				$aa = $amino[$i];
				$matr =~ s/^\s+(\-*\d+)\s+/ /;
				$seqs{$amino}{$aa} = $1;
				print "$amino $aa ".$seqs{$amino}{$aa}."\n";
				$i++;
			}
		}
	}
	return;
}
sub getPhat{
	my ($amino, $i, @l, $aa, $matr);
	open (MAT, "$pwd/phat.txt");
	foreach $matr (<MAT>){
		if ($matr =~ /\d/){
			$matr =~ s/([A-Z])//;
			$amino = $1;
			$i = 0;
			while ($i < @amino-1){
				$aa = $amino[$i];
				$matr =~ s/^\s+(\-*\d+)\s+/ /;
				$phat{$amino}{$aa} = int(($1 * 4.76 )+ 50);
				print "$amino $aa ".$phat{$amino}{$aa}."\n";
				$i++;
			}
		}
	}
	return;
}				
#print "total entries processed = $g_c\n";
sub round {
    my($number) = shift;
    return int($number + .44445);
}
