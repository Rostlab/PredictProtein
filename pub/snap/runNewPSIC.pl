#!/usr/bin/perl -w
select STDOUT; $| = 1;

#August 2, 2005
#This file will transform the blast files into form needed for PSIC predictions
#blast files need to be flag m-6 (blunt ends, no identities)

#it will also eliminate any sequences with sequence identity not in range of 30 to 94
#and with less than 50 residues aligning

#First argument is the input file
$infile = $ARGV[0];

#second argument is the psic output directory
$outDir = $ARGV[1];

#third argument is the blast directory
$blastdir = $ARGV[2];

#this is whether we ran this before
$run  = $ARGV[3];


#this is the installation dir
$homeDir = $ARGV[4];

if (!$run){
	$run = 0;
}

$name = $infile;
$name =~ s/(.+\/)*//g;
$name =~ s/\.\d+\./\./;
$name =~ s/\.fasta//;
$f_name = $name;
$blastfile = $name.".blast";
$clustal_file = $name.".clustal";
$psicinfile = $name.".psicin";
$psicout = $name.".psicout";
$finalpsic = $name.".out";

if (!(-e "$infile")){
	print "No $infile found\n";
	exit;
}

$i = 0;
$space = "";
while ($i < 61){
	$space .= "_";
	$i++;
}

#first check that we have at least 50 residues to align
open (IN, "$infile");
@data = <IN>;
close IN;
$file = "@data";
$file =~ s/\>.+\n//;
$file =~ s/[^A-Z]//g;
$seq = $file;
$number = length($file);
if ($number < 50){
	print "Sequence is less than 50 aa in length: $number\n";
	exit;
}

if (-e  "$outDir/$finalpsic"){
	print "$finalpsic exists\n";
	#`rm $blastdir/$name.*`;
	exit;
}
if (-e "$blastdir/$psicout"){
	print "running with existing $psicout\n";
	$flag = 1;
}
elsif (-e "$blastdir/$psicinfile"){
	print "running with existing $psicinfile\n";
	$flag = 2;
}
elsif (-e "$blastdir/$name.aln"){
	print "running with existing $name.aln\n";
	$flag = 3;
}
else{
	$flag = 4;
	#run blast
	if (!(-e "$blastdir/$blastfile")){
		#EDIT AS NEEDED BLAST DIRECTORY AND DATABASE DIRECTORY
		`/usr/pub/molbio/bin/blastpgp -d /data/blast/big -i $infile -j 1 -h 0.001 -o $blastdir/$blastfile -b 300`;
	}
	else{
		print "Using existing Blast: $blastfile\n";
	}
	$size = 0;
	$size = `du -h $blastdir/$blastfile`;
	$size =~ s/(^\d+)M//;
	$size = $1;
	if (($size) and ($size > 100)){
		$num = int(100/($size/300));
		print "Too big. Rerun $blastfile with $num aligns\n";
		#EDIT AS NEEDED BLAST DIRECTORY AND DATABASE DIRECTORY
		`/usr/pub/molbio/bin/blastpgp -d /data/blast/big -i $infile -j 1 -h 0.001 -o $blastdir/$blastfile -b $num`;
		$size = `du -h $blastdir/$blastfile`;
		$size =~ s/(^\d+)M//;
		$size = $1;
	}
	open (IN, "$blastdir/$blastfile");
	@data = <IN>;
	close IN;
	$file = "@data";
	$file_p = &checkBlast($file, $run);
	if ($file_p eq "failed"){
		print "Exiting: Bad Blast of $blastfile\n";
		exit;
	}		
	#if dealing with nonempty file
	if ($file =~ /\w/){	
		print "processing blast\n";
		@file = split (/\>/, $file_p);
		#now we need to get the sequences
		%seq = ();
		$count = 1;
		open (CLUST, ">$blastdir/$clustal_file");
		$file[0] =~ s/(\d+)\s+letters//;
		$seq_length = $1;
		if (!($number == $seq_length)){
			print "Sequence length in blast $seq_length, doesn't agree with actual sequence length $number\n";
			exit;
		}
		$rare = 0;
		$large = 0;
		print CLUST ">query\n".$seq."\n";
		foreach $l (1..@file-1){
			$line = $file[$l];
			$line =~ s/Identities\s+\=\s+\d+\/(\d+)\s+\((\d+)\%\)//;
			$id = $2;
			$length = $1;
			if ($length < 50){
				print "Alignment length shorter than 50: $length\n";
				next;
			}
			if (($id > 94) or ($id < 30)){
				if ($id > 94){
					$large++;
				}
				print "Seq ID bad: $id\n";
				next;
			}
			@sub = split (/Positives.+\n/, $line);
			$first = $sub[1];
			$rare = 1;
			#get subject
			while ($first =~ /Sbjct/){
				$first =~ s/Sbjct\:\s+\d+\s+([A-Z\-]+)\s+\d+\s*\n//;
				$seq = $1;
				if (exists $seq{$count}){
					$seq{$count} .= $seq;
				}
				else{
					$seq{$count} = $seq;
				}
			}
			$seq{$count} =~ s/\-//g;
			print CLUST ">name$count\n".$seq{$count}."\n";
			$count++;			
		}
	
		$total = keys %seq;
		print "Total keys gotten = $total\n";
		close CLUST;
		if ((!$rare) or (!$total) or ($total <= 10)){
			if ((!$total) and ($large == (@file-1))){
				#EDIT AS NEEDED BLAST DIRECTORY AND DATABASE DIRECTORY
				`/usr/pub/molbio/bin/blastpgp -d /data/blast/big -i $infile -j 1 -h 0.001 -o $blastdir/$blastfile -b 400`;
			}
			print "No needed alignments exist for $clustal_file\n";
			if (!$run and !$total){
				$return = &checkBlast($file, 2);
				if ($return =~ /fail/){
					exit;
				}
				else{
					print "reran blast with more allowed matches\n";
					`perl runNewPSIC.pl $infile $outDir $blastdir 1 $homeDir`;
					exit;
				}
			}
			else{
				exit;
			}
		}
	}
}
if ($flag >= 4){ 
	#EDIT AS NEEDED CLUSTAL DIRECTORY 
	print "/usr/pub/molbio/clustalw1.82/clustalw $blastdir/$clustal_file\n";
	`/usr/pub/molbio/clustalw1.82/clustalw $blastdir/$clustal_file`;
}
if ($flag >= 3){
	%seq = ();
	open (IN, "$blastdir/$name.aln") || die "Can't open $blastdir/$name.aln\n";
	foreach $line (<IN>){
		if ($line =~ /CLUSTAL/){
			next;
		}
		if ($line =~ /\w/){
			$line =~ s/^([^\s]+)\s+([A-Z]|\-)/$2/;
			$name = $1;
			$line =~ s/[^A-Z-]//g;
			if (exists $seq{$name}){
				$seq{$name} .= $line;
			}
			else{
				$seq{$name} = $line;
			}
		}
	}
	close IN;
	open (OUT, ">$blastdir/$psicinfile");
	print OUT "CLUSTAL\n\n";
	foreach $key (keys %seq){
		if ($key =~ /query/){
			print OUT $space."QUERYA ".$seq{$key}."\n";		
		}
		else{
			print OUT $space."NAMEAB ".$seq{$key}."\n";
		}
	}
	close OUT;
}
if ($flag >=2){
	`$homeDir/psic $blastdir/$psicinfile $homeDir/Blosum62.txt $blastdir/$psicout`;
}

open (IN, "$blastdir/$psicout") || die "File $blastdir/$psicout doesn't exist\n";
open (OUT, ">$outDir/$finalpsic") || die "Can't open $outDir/$finalpsic\n";
$count = 0;
$q = $seq{"query"};
$q =~ s/([A-Z\-])/$1 /g;
@query = split (/ /,$q);
$i = -2;

foreach $line (<IN>){
	if ($i == -2){
		$i++;
		next;
	}
	elsif ($i == -1){
		print OUT $line;
		$i++;
		next;
	}
	elsif ($query[$i] =~ /[A-Z]/){
		$line =~ s/^\d+\s+//;
		print OUT "$count $line";
		$count++;
		$i++;
	}
	else{
		$i++;
	}
}
close IN;
close OUT;

$f_name =~ s/\_query//;
#$end = `tail $outDir/$f_name.asci`;
#$end =~ s/\n\s+(\d+) .+\n\n//g;
#$end = $1;
#if (!($end == $count)){
#	print "wrong line length : asci $end vs psic $count\n";
#	`mv $outDir/$finalpsic $blastdir`;
#}
#else{ 
`mv $blastdir/$f_name\_query.out $blastdir/$f_name.out`;
#`rm $blastdir/$f_name\_query*`;	
#}
#get rid of this
#`rm $blastdir/$f_name.aln $blastdir/$f_name.blast $blastdir/$f_name.dnd $blastdir/$f_name.psic*`;
sub checkBlast{
	my $file = shift @_;
	my $run = shift @_;
	my $file_p;
	#check if there are hits
	if ($file =~ /No hits found/){
		return "failed";
	}
	elsif (!($file =~ /\w/)){
		if ($run == 0){
			print "Incorrect blast file: $blastdir/$blastfile\n";
			#EDIT AS NEEDED BLAST DIRECTORY AND DATABASE DIRECTORY
			`/usr/pub/molbio/bin/blastpgp -d /data/blast/big -i $infile -j 1 -h 0.001 -o $blastdir/$blastfile -b 100`;	
			open (IN, "$blastdir/$blastfile");
			@data = <IN>;
			close IN;
			$file = "@data";
			$file = &checkBlast($file, 1);
		}
		elsif ($run == 2){
			#EDIT AS NEEDED BLAST DIRECTORY AND DATABASE DIRECTORY
			`/usr/pub/molbio/bin/blastpgp -d /data/blast/big -i $infile -j 2 -h 0.1 -o $blastdir/$blastfile -b 500`;	
			open (IN, "$blastdir/$blastfile");
			@data = <IN>;
			close IN;
			$file = "@data";
			$file = &checkBlast($file, 1);
		}
		else{
			return "failed";
		}
	}
	return $file;
}
