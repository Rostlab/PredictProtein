#!/usr/bin/perl -w

#this is a sub collection for extracting 
#needed information for each sequence

sub runAll{
	my ($dir, $name, $file, $hssp, $ckp) = @_;
	$prof = $hssp;
	$prof =~ s/hssp.*/rdbProf/;
	print "prof = $prof\n"x10;
	$prof =~ s/(.+\/)*//;

	if ($ckp){
		print "/usr/pub/molbio/blast/blastpgp -i $dir/$name/$file -d /data/blast/big -e 0.001 -j 5 -Q $dir/$name/$name.asci -R $ckp -b 3000 -h 0.001 -o $dir/$name/$name.blastpgp\n";
		`/usr/pub/molbio/blast/blastpgp -i $dir/$name/$file -d /data/blast/big -e 0.001 -j 5 -Q $dir/$name/$name.asci -R $ckp -b 3000 -h 0.001 -o $dir/$name/$name.blastpgp`
	}
	if (!(-e "$dir/$name/$name.blastswiss")){
		`/usr/pub/molbio/blast/blastpgp -i $dir/$name/$file -d /data/blast/swiss -e 0.001 -o $dir/$name/$name.blastswiss`;	
		if (!(-e "$dir/$name/$name.blastswiss")){
			$error = "Couldn't run blastpgp to get $name.blastswiss file\n /data/molbio/blast/blastpgp -i $dir/$name/$file -d /data/blast/swiss -e 0.001 -o $dir/$name/$name.blastswiss\n";
			return $error;
		}
	}
	if (!(-e "$dir/$name/$name.NArdbProf")){
#		`/usr/pub/molbio/prof/prof $dir/$name/$file dirOut=$dir/$name`;
		`/nfs/data5/users/ppuser/server/pub/prof/prof $dir/$name/$file dirOut=$dir/$name`;
		`mv $dir/$name/$name\_query.rdbProf $dir/$name/$name.NArdbProf`;
		if (!(-e "$dir/$name/$name.NArdbProf")){
			$error = "Couldn't run prof.pl to get $dir/$name.NArdbProf file\n";
			return $error;
		}
	}
	#SIFT and PSIC are not required pieces of information, so we don't check for them after extraction
	if (!(-e "$dir/$name/$name.SIFTprediction")){
#		print "sift2.1/bin/SIFT.csh $dir/$name/$name\_query.fasta /data/blast/big_80 $dir/$name/$name.muts 2.75\n";
		`$dir/sift2.1/bin/SIFT.csh $dir/$name/$name\_query.fasta /data/blast/big_80 $dir/$name/$name.muts 2.75`;
		`mv $dir/sift2.1/tmp/$name\_query.SIFTprediction $dir/$name/$name.SIFTprediction`;
		`rm $dir/sift2.1/tmp/$name\_*`;
	}
	if (!(-e "$dir/$name/$name.out")){
	    print "runall: perl $dir/runNewPSIC.pl $dir/$name/$name\_query.fasta $dir/$name $dir/$name 0 $dir\n";
	    `perl $dir/runNewPSIC.pl $dir/$name/$name\_query.fasta $dir/$name $dir/$name 0 $dir`; 
	}
	else{
	    print "runall: $dir/$name/$name.out exists\n";
	}
	

	if (!(-e "$dir/$name/$name.ArdbProf")){
#	    `/usr/pub/molbio/prof/prof both nonice $hssp dirOut=$dir/$name/`;
	    print `/nfs/data5/users/ppuser/server/pub/prof/prof  both nonice $hssp dirOut=$dir/$name/`;
	    `mv $dir/$name/$prof $dir/$name/$name.ArdbProf`;
	    print "mv $dir/$name/$prof $dir/$name/$name.ArdbProf\n"x10;
	    if (!(-e "$dir/$name/$name.ArdbProf")){
		$error = "Couldn't run prof.pl to get $dir/$name/$name.ArdbProf file\n";
		return $error;
	    }
	}
	#this stuff is now gotten from PROF interface (October 23,2006)
	#if (!(-e "$name/$name.rdbProf")){
	#	if ((!(-e "$name/$name.saf")) or (!(-e "$name/$name.asci"))){
	#		`/usr/pub/molbio/perl/blastpgp.pl $name/$file dbFinal=/data/blast/big dbTrain=/data/blast/big argBlastX="-j 4 -h 0.001 -b 3000" argBlastB="-j 4 -h 0.001 -b 3000 -Q $name/$name.asci -C $name/$name.ckp" saf=$name/$name.saf maxAli=3000 eSaf=1 ARCH=LINUX`;
	#		if (!(-e "$name/$name.saf")){
	#			$error = "Couldn't run blastpgp.pl to get $name.saf file\n /usr/pub/molbio/perl/blastpgp.pl $name/$file dbFinal=/data/blast/big dbTrain=/data/blast/big argBlastX=\"-j 4 -h 0.001 -b 3000\" argBlastB=\"-j 4 -h 0.001 -b 3000 -Q $name/$name.asci -C $name/$name.ckp\" saf=$name/$name.saf maxAli=3000 eSaf=1 ARCH=LINUX\n";
	#			return $error;
	#		}
	#		#`rm $name\_query.blastpgp`;
	#	}
	#	if (!(-e "$name/$name.safFil")){
	#		`/home/rost/perl/scr/safFilterRed.pl $name/$name.saf red=85 fileOut=$name/$name.safFil`;
	#		if (!(-e "$name/$name.safFil")){			
	#			$error = "Couldn't run safFilterRed.pl to get $name.safFil file\n";
	#			return $error;
	#		}
	#	}
	#	if (!(-e "$name/$name.hssp")){
	#		`/usr/pub/molbio/prof/scr/copf.pl $name/$name.safFil $name/$name.hssp exeConvertSeq=/home/rost/pub/bin/convert_seq_big.LINUX`;
	#		if (!(-e "$name/$name.hssp")){
	#			$error = "Couldn't run copf.pl to get $name.hssp file\n";
	#			return $error;
	#		}
	#	}
	#	if (!(-e "$name/$name-fil.hssp")){
	#		`/usr/pub/molbio/prof/scr/hssp_filter.pl $name/$name.hssp red=80 dirOut=$name exeFilterHssp=/home/rost/pub/bin/filter_hssp_big.LINUX`;
	#		if (!(-e "$name/$name-fil.hssp")){
	#			$error = "Couldn't run hssp_filter.pl to get $name-fil.hssp file\n";
	#			return $error;
	#		}
	#	}
	#	if (!(-e "$name/$name-fil.rdbProf")){	
	#		`/usr/pub/molbio/prof/prof both nonice $name/$name-fil.hssp dirOut=$name/`;
	#		if (!(-e "$name/$name-fil.rdbProf")){
	#			`/usr/pub/molbio/prof/scr/hssp_filter.pl $name/$name.hssp red=60 dirOut=$name exeFilterHssp=/home/rost/pub/bin/filter_hssp_big.LINUX`;
	#			`/usr/pub/molbio/prof/prof both nonice $name/$name-fil.hssp dirOut=$name/`;
	#			if (!(-e "$name/$name-fil.rdbProf")){
	#				$error = "Couldn't run prof.pl to get $name-fil.hssp file\n";
	#				return $error;
	#			}
	#		}
	#	}
	#	print "/usr/pub/molbio/prof/prof $name/$file dirOut=$name\n";
		
	#}
		
	#if (!(-e "$name/$name.pfam")){
	#	open (IN, ">$name/list.$name") || die "Can't open $name/list.$name";
	#	print IN "$file";
	#	close IN;
	#	`perl run_hmmer.pl -l $name/list.$name -dirSeq $name -dirOut $name`;
	#	`mv $name/$name\_query.pfam $name/$name.pfam`;
	#	if (!(-e "$name/$name.pfam")){
	#		$error = "Couldn't run run_hmmer.pl to get $name.pfam file\n";
	#		return $error;
	#	}
	#	`rm $name/list.$name`;
	#}
	#if (!(-e "$name/$name.profbval")){
	#	`perl /home/schles/profbval/runPROFbvalAlign.pl $name/$name-fil.hssp $name/$name-fil.rdbProf $name`;
	#	if (!(-e "$name/$name.profbval")){
	#		$error = "Couldn't run runPROFbvalAlign.pl to get $name.profbval file\n";
	#		return $error;
	#	}
	#}
	
	
	
	
	return 1;
}

sub extractAll{
	my ($dir, $name, $file, $muts) = @_;
	$file =~ s/(.)/$1 /g;
	my $check = 0;
	my @file = split (/ /,$file);
	@muts = split (/\n/, $muts);
	open (MAIN, ">$dir/$name/$name.mutant_seqs") || die "Can't open $dir/$name/$name.mutant_seqs\n";
	foreach $mut (@muts){
		if ($mut =~ /[A-Za-z]/){
			$mut =~ tr/a-z/A-Z/;
			if ($mut =~ /\.*([A-Z])\s*(\d+)\s*([A-Z])[^A-Za-z]*/){
				$org = $1;
				$pos = $2;
				$sub = $3;
				@temp = @file;
				#print MAIN "here 2 -- $mut\n";
				if ($temp[$pos-1] eq $org){
					$temp[$pos-1] = $sub;
					print MAIN ">$name.$org$pos$sub 0\n@temp\n";
					if (!(-e "$dir/$name/$name.$org$pos$sub.rdbProf")){
						open (OUT, ">$dir/$name/$name.$org$pos$sub.f") || die "Can't open $dir/$name/$name.$org$pos$sub.f\n";
						print OUT ">$name.$org$pos$sub.f\n@temp";
						close OUT;
#						`/usr/pub/molbio/prof/prof $dir/$name/$name.$org$pos$sub.f dirOut=$dir/$name`;
						print "/nfs/data5/users/ppuser/server/pub/prof/prof $dir/$name/$name.$org$pos$sub.f dirOut=$dir/$name\n";
						`/nfs/data5/users/ppuser/server/pub/prof/prof $dir/$name/$name.$org$pos$sub.f dirOut=$dir/$name`;

						if (!(-e "$dir/$name/$name.$org$pos$sub.rdbProf")){
							$error = "Couldn't run prof to get $dir/$name/$name.$org$pos$sub.rdbProf";
							return $error;
						}
						#`rm $name/$name.$org$pos$sub.fasta`;
					}
					$check = 1;
				}
				else{
					$res = $temp[$pos-1];
					$error = "Residue at pos $pos is $res, not $org (mutant $org$pos$sub)\n";
					return $error;
				}
			}
			else{
				$error = "Mutant $mut is of wrong format: name = $name file = $file mu = $muts";
				return $error;
			}
		}
	}
	close MAIN;
	if (!$check){
		$error = "No mutations found in given mutation file\n";
		return $error;
	}
	else{
		return 1;
	}
}
1;
