#!/usr/bin/perl -w


#########################################
#yana.bromberg@dbmi.columbia.edu	#
#October 23, 2006			#
#########################################


#this is the main script to run a single sequence through the 
#network to gain a prediction. Takes as input the sequence,
#the mutant list , and the cutoff value for the difference between output nodes
use Getopt::Long;
$pwd = "$ENV{HOME}/server/pub/snap/";
use lib '.';
require "$pwd/runAll.pl";
$Lok = GetOptions ('i=s' => \$seq_n,
                   'm=s' => \$mutants,
                   'o=s' => \$out_file,
                   'p=s' => \$hssp_file,
                   'b=s'  => \$bval_file,
		   'x=s' => \$asci_file,
                   'f=s'  => \$pfam_file,
		   'r=i' => \$min_ri,
		   'e=i' => \$min_ep,
		   'help' => \$help,
                   );
if ($help){
	print STDERR "need\n";
	print STDERR "-i Input fasta file\n";
	print STDERR "-m Mutant file\n";
	print STDERR "-o Output file name\n";
	print STDERR "-p Prof, -b Bval, -x PSI-BLAST matrix, -f Pfam\n";
	exit(1);
}
if ( ! $Lok ) {
    print STDERR "Invalid arguments found, -h or --help for help\n";
    exit(1);
}
#set defs
if (! $min_ri){
	$min_ri = 0;
}
if (! $min_ep){
	$min_ep = 50;
}
#get the sequence from file
if (!(-e "$seq_n")){
	die "1: Can't open $seq_n\n";
}
if (!(-e "$mutants")){
	die "2: Can't open $mutants\n";
}
if (!(-e "$hssp_file")){
	die "3: Can't open $hssp_file\n";
}
if (!(-e "$bval_file")){
	die "4: Can't open $bval_file\n";
}
if (!(-e "$asci_file")){
	die "5: Can't open $asci_file\n";
}
if (!(-e "$pfam_file")){
	die "6: Can't open $pfam_file\n";
}

$prof_file = $hssp_file;
$prof_file =~ s/hssp.*/ArdbProf/;
$prof_file =~ s/(.+\/)*//;
#print "prof $prof_file\n";
#set up ri/acc relationship
$acc{"non"}{"0"} = 58;
$acc{"non"}{"1"} = 63;
$acc{"non"}{"2"} = 70;
$acc{"non"}{"3"} = 78;
$acc{"non"}{"4"} = 82;
$acc{"non"}{"5"} = 87;
$acc{"non"}{"6"} = 93;
$acc{"non"}{"7"} = 96;
$acc{"non"}{"8"} = 97;
$acc{"non"}{"9"} = 100;
$acc{"neu"}{"0"} = 53;
$acc{"neu"}{"1"} = 60;
$acc{"neu"}{"2"} = 69;
$acc{"neu"}{"3"} = 78;
$acc{"neu"}{"4"} = 85;
$acc{"neu"}{"5"} = 89;
$acc{"neu"}{"6"} = 92;
$acc{"neu"}{"7"} = 94;
$acc{"neu"}{"8"} = 96;
$acc{"neu"}{"9"} = 100;


#hard-coding cutoff for all mutants
$temp{"B"}{"cut"} = 1;
$temp{"I"}{"cut"} = 1;
$temp{"E"}{"cut"} = 1;

#print "Cutoff for buried:".$temp{"B"}{"cut"}."\n";
#print "Cutoff for intermediate:".$temp{"I"}{"cut"}."\n";
#print "Cutoff for exposed:".$temp{"E"}{"cut"}."\n";

# slurp the fasta file
$seq="";
open (FH, "$seq_n")||die "Cannot open file=$seq_n. $!\n";
while( <FH> ) {
    $seq.= $_ ;
}
close FH;
#$seq = `more $seq_n`;
#$seq =~ s/\>([^\s]+).*\n//;
$seq =~ s/\>.+\n*//;
$seq =~ s/[^A-Za-z]//g;
$seq =~ tr/a-z/A-Z/;
$name = $seq_n;
$name =~ s/(.+\/)*(.+)\.fasta/$2/;
#print "name = $name\n";
$name =~ s/\_query//;
#create a correctly formatted file
if (length($name) > 11){
	$name =~ s/.+(.{11})$//;
	$name = $1;
}

`mkdir $pwd/$name`;
open (FTEMP, ">$pwd/$name/$name.command");
print FTEMP "i=$seq_n,m=$mutants,o=$out_file,p=$hssp_file,b=$bval_file,x=$asci_file,f=$pfam_file\n";
close FTEMP;
`cp $mutants $pwd/$name/$name.muts`;

$file_name = $name."_query.fasta";
open (IN, ">$pwd/$name/$file_name")|| die "Can't create file $pwd/$name/$file_name\n";
print IN ">$name\n";
$temp = $seq;
$temp =~ s/([A-Z]{60})/$1\n/g;
print IN $temp."\n";
close IN;
#`rm $seq_n`;
#die;
#get the mutant list
open (IN, "$pwd/$name/$name.muts") || die "2: Can't open $pwd/$name/$name.muts\n";
@muts = <IN>;
$muts = "@muts";
close IN;

#print "Running extraction\n";
#print "pwd=$pwd\n";
#run the extraction itself for each of the mutants
$status = &extractAll($pwd, $name, $seq, $muts);
if ($status =~ /[A-Za-z]/){
	die "run of mutants extractions failed: $status\n";
}
#run all the needed files for the extraction
$status = &runAll ($pwd, $name, $file_name, $hssp_file);
if ($status =~ /[A-Za-z]/){
	die "run of sequence extractions failed: $status\n";
}

#print "done extracting! processing data\n";

#extract everything for each mutant
if ((!(-e "$pwd/$name/ProcessedJctE")) or (!(-e "$pwd/$name/ProcessedJctB")) or (!(-e "$pwd/$name/ProcessedJctI")) ){
	`perl $pwd/extractAllSingle.pl $pwd/$name/$name.mutant_seqs $pwd $name $pwd/$name/$name.ArdbProf $bval_file $asci_file $pfam_file`;
	#print "perl extractAllSingle.pl $name/$name.mutant_seqs $name\n";
	#print "done processing. Getting ready to run networks\n";
}
@temp = ('B','I','E');
$length = 2;
$opt = "02112213101";
$hid = 50;
$in = 195;	
$al = 0.1;
open (OUT, ">$out_file") || die "Can't open $pwd/$out_file\n";
print OUT "Result of SNAP prediction\n";
print OUT "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
print OUT "Yana Bromberg and Burkhard Rost\n";
print OUT "NAR (2007)\n";
print OUT "_______________________________\n";
print OUT "#Query sequence  :  $name      \n";
print OUT "Including only predictions with:\n";
print OUT " 	RI >= $min_ri \n";
print OUT "	Expected Accuracy >= $min_ep%\n\n";
print OUT "nsSNP\tPrediction\tReliability Index\tExpected Accuracy\n";
print OUT "-----\t------------\t-------------------\t-------------------\n";
foreach $temp (@temp){
	if (`tail $pwd/$name/proc$temp`){
		if (!(-e "$pwd/$name/ProcessedJct$temp")){
			#print "perl $pwd/getExtractedSingle.pl $pwd/$name/proc$temp $pwd/$name\n";
			`perl $pwd/getExtractedSingle.pl $pwd/$name/proc$temp $pwd/$name`;
		}
		#print "perl  $pwd/processJctMutsSingle.pl $name/ProcessedJct$temp $length $opt $name/\n";
		`perl  $pwd/processJctMutsSingle.pl $pwd/$name/ProcessedJct$temp $length $opt $pwd/$name/`;
		$valSum = `more $pwd/$name/Jct$temp.L$length.$opt.sum`;
		$valSum =~ s/total (\d+) entries//;
		$valTot = $1;
		#if we are looing at the average of outputs
		#get the jct sets for each
		#print "running network for $temp mutants \n";
		open (MUTS, "$pwd/$name/proc$temp");
		$mi = 0;
		foreach $m (<MUTS>){
			$m =~ s/\s+\d+//;
                	$m =~ s/$name\.//;
               		$m =~ s/\n//;
			if ($m =~ /[A-Z]\d+[A-Z]/){
				#print "m = $m\n";
				$muts[$mi] = $m;
				$mi++;
			}
		}
		close MUTS;
		@sub_d = `ls $pwd/Training*jct*`;
		foreach $jct (@sub_d){
			$jct =~ s/\n//;
			if ($jct){
				`perl  $pwd/TabbedCreateNNinputFiles.pl $pwd/$name/Jct$temp.L$length.$opt $in $hid 2 2 $valTot 1 1 $valTot $jct test $al 0.001 1 $pwd/$name $pwd/$name`;
				` $pwd/NN/NetRun.LINUX $pwd/$name/inJct$temp.L$length.$opt-par`;
				&calculate();
			}
		}
		&printStuff();
	}
	else{
		print STDERR "proc$temp doesn't contain data\n";
	}
}
close OUT;
#uncomment this to remove the folder where all work was done
#`rm -r $pwd/$name`;

sub calculate{
	open (FILE, "$pwd/$name/outJct$temp.L$length.$opt-out1") || die "Can't open $pwd/$name/outJct$temp.L$length.$opt-out1\n";
	@data = <FILE>;
	close FILE;
	foreach $i (0..$mi-1){
		@split = split (/\s+/,$data[$i+43]);
		$dif1[$i] += $split[2];
		$dif2[$i] += $split[3];
		$collection[$i] .= " $split[2] $split[3] |";
		
	}
}
sub printStuff{
	foreach $i (0..$mi-1){
		$sum = int(($dif1[$i]/10) - ($dif2[$i]/10));
		#print "$muts[$i] $test[$i] => $collection[$i] sum = $sum";
	
		$r = int(abs($sum)/10);
		if ($r >= $min_ri){
			if (($sum >= $temp{$temp}{"cut"}) and ($acc{"non"}{$r} >= $min_ep)){
				print OUT "$muts[$i]\tNon-neutral\t\t$r\t\t\t".$acc{"non"}{$r}."%\n";
			}
			elsif ($acc{"neu"}{$r} >= $min_ep){
				print OUT "$muts[$i]\t Neutral \t\t$r\t\t\t".$acc{"neu"}{$r}."%\n";
			}
		}
		$collection[$i] = "";
		$sum = 0;
		$dif1[$i] = 0;
		$dif2[$i] = 0;		
	}
}
exit(0);
