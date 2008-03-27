#!/usr/bin/perl
use Cwd;
use File::Copy;
if (@ARGV<1)  {
	die "\nUsage: $0 [fasta]\n";
	}
$file=$ARGV[0];
$fileroot= $file;
$fileroot=~ s/\.f//;
$fasta=$file;
$blastpgp="$fileroot" . ".blastpgp";
$hssp= "$fileroot" . ".hssp";
$saf=  "$fileroot" . ".saf";
$hsspfil="$fileroot-fil.hssp";
$file1= "$fileroot-fil.rdbProf";
print "### Blasting\n";
system ("/home2/pub/molbio/blast/blastpgp -i $fasta -j 3 -d /data/blast/big -o $blastpgp ");
print "### Converting to SAF format\n";
system ("perl /home2/pub/molbio/perl/blast2saf.pl $blastpgp maxAli=3000 eSaf=1");
system ("mv *.saf saf/");
print "### Converting to HSSP format\n";
system ("/home2/rost/pub/prof/scr/copf.pl $saf hssp");
system ("mv *.hssp hssp/");
print "### Filtering HSSP file\n";
system ("/home2/rost/pub/prof/scr/hssp_filter.pl $hssp red=80");
system ("mv *.hssp hssp/");
print "### Running PROF\n";
system ("/home2/rost/pub/prof/prof $hsspfil");
print "### DONE work on $fileroot?!\n";
$dataFile= $fileroot . ".data";
open (FOUT, ">$dataFile") || print "cant open file $!";
undef @res;undef @res;undef $end;undef@PREL; undef @PACC, undef @otL; undef @otE;
undef @otH;undef @RI_A;$exp=0;$s=0;$v=0;$expCont=0;undef @RI_A2;undef @RI_S;
undef @secC; $secC=$Helix=$Beta=$Loop=0; $lengthA=$lengthB=$lengthC=0;undef @resNum;
undef @A;undef @C;undef @D;undef @E;undef @F;undef @G;undef @H;undef @I;undef @K;undef @L;
undef @M;undef @N;undef @P;undef @Q;undef @R;undef @S;undef @T;undef @V;undef @W;undef @Y;undef @meida;
if (!open(FILE, "$file1"))  {
	die "cant open $file1\n";
	}		
loop666:while ($line=<FILE>) {####################change this loop see file arath_fr13110##############
	if ($line=~/No	AA	OHEL	PHEL	RI_S	OACC	PACC	OREL	PREL	RI_A/)  {
		last loop666;
		}
	}
#find the right columns
	@meida= split(/\t/,$line);
	for ($o=0; $o<scalar(@meida); $o++)  {
		if ($meida[$o] eq 'No')  {
			$NoM=$o;
			}
		elsif ($meida[$o] eq 'AA')  {
			$AAM=$o;
			}			
		elsif ($meida[$o] eq 'PHEL')  {
			$PHELM=$o;
			}				
		elsif ($meida[$o] eq 'RI_S')  {
			$RI_SM=$o;
			}
		elsif ($meida[$o] eq 'PACC')  {
			$PACCM=$o;
			}				
		elsif ($meida[$o] eq 'PREL')  {
			$PRELM=$o;
			}				
		elsif ($meida[$o] eq 'RI_A')  {
			$RI_AM=$o;
			}
		elsif ($meida[$o] eq 'OtH')  {
			$otHM=$o;
			}									
		elsif ($meida[$o] eq 'OtE')  {
			$otEM=$o;
			}				
		elsif ($meida[$o] eq 'OtL')  {
			$otLM=$o;
			last;
			}
		}
loop3:while ($line=<FILE>)  {
	undef @info;
	$line=~ s/\n//;
	@info=split (/\t/,$line);
	$resNum=$info[$NoM]; $res=$info[$AAM];$secC=$info[$PHELM];$otH=$info[$otHM]; $otE=$info[$otEM]; $otL=$info[$otLM]; $RI_S=$info[$RI_SM]; $PACC=$info[$PACCM];$RI_A=$info[$RI_AM];
	$PREL=$info[$PRELM];
	if ($secC eq 'E')  { $Beta++;}
	elsif ($secC eq 'H')  {$Helix++;}
	else {$Loop++;}
	if ($PREL>=5) {$exp++;}
	if (($resNum=~/[a-z]|A-Z]/ ) ||($otH=~/[a-z]|A-Z]/ )||($otE=~/[a-z]|A-Z]/ )||($otL=~/[a-z]|A-Z]/ )||($RI_S=~/[a-z]|A-Z]/ )||($PACC=~/[a-z]|A-Z]/ )||($RI_A=~/[a-z]|A-Z]/ )||($PREL=~/[a-z]|A-Z]/ )){
		print "\n*******@info\t$file*******\n";
		}
	push (@res,$res); push (@otH,$otH); push (@otE,$otE); push (@secC,$secC); push (@otL,$otL); push (@PACC,$PACC/3);push (@RI_S,$RI_S);
	push (@PREL,$PREL);$RI_A2=$RI_A; push (@RI_A2,$RI_A2); $RI_A=$RI_A/9*100;push (@resNum,$resNum);
	use integer;
	$RI_A=$RI_A*1;
	push (@RI_A,$RI_A);
	no integer;
	}
close (FILE);
if (scalar@res<11) {
	die "sequence is too short";
	}
$exp=$exp/(scalar@PREL)*100;
use integer;
$expCont=$exp*1;
no integer;
$win=1;
if (scalar@res<60)  {$lengthA=100;$lengthB=0;$lengthC=0;}
elsif ((scalar@res>=60) &&(scalar@res<90)) {$lengthA=50;$lengthB=50;$lengthC=0;}
elsif ((scalar@res>=90) &&(scalar@res<180)) {$lengthA=0;$lengthB=100;$lengthC=0;}
elsif ((scalar@res>=180) &&(scalar@res<240)) {$lengthA=0;$lengthB=50;$lengthC=50;}
else {$lengthA=0;$lengthB=0;$lengthC=100;}
$end=(scalar@res)-($win-1)/2;
close (FILE);
if (!open(FILE, "$hsspfil"))  {
	die "nein lustig, cant open $hsspfil $!";
	}
loop155:while ($line=<FILE>)  {
	if ($line=~ /^## SEQUENCE PROFILE AND ENTROPY/)  {
		last loop155;
		}
	}
<FILE>;
while ($line=<FILE>)  {
	if ($line=~ /^\/\/\n/)  {last;}
	$V[$s]=substr($line, 12,4);$V[$s]=~ s/\s//g;
	$L[$s]=substr($line, 16,4);$L[$s]=~ s/\s//g;
	$I[$s]=substr($line, 20,4);$I[$s]=~ s/\s//g;
	$M[$s]=substr($line, 24,4);$M[$s]=~ s/\s//g;		
	$F[$s]=substr($line, 28,4);$F[$s]=~ s/\s//g;
	$W[$s]=substr($line, 32,4);$W[$s]=~ s/\s//g;		
	$Y[$s]=substr($line, 36,4);$Y[$s]=~ s/\s//g;
	$G[$s]=substr($line, 40,4);$G[$s]=~ s/\s//g;		
	$A[$s]=substr($line, 44,4);$A[$s]=~ s/\s//g;
	$P[$s]=substr($line, 48,4);$P[$s]=~ s/\s//g;		
	$S[$s]=substr($line, 52,4);$S[$s]=~ s/\s//g;
	$T[$s]=substr($line, 56,4);$T[$s]=~ s/\s//g;
	$C[$s]=substr($line, 60,4);$C[$s]=~ s/\s//g;		
	$H[$s]=substr($line, 64,4);$H[$s]=~ s/\s//g;
	$R[$s]=substr($line, 68,4);$R[$s]=~ s/\s//g;		
	$K[$s]=substr($line, 72,4);$K[$s]=~ s/\s//g;
	$Q[$s]=substr($line, 76,4);$Q[$s]=~ s/\s//g;
	$E[$s]=substr($line, 80,4);$E[$s]=~ s/\s//g;		
	$N[$s]=substr($line, 84,4);$N[$s]=~ s/\s//g;
	$D[$s]=substr($line, 88,4);$D[$s]=~ s/\s//g;
	$s++;
	}
close (FILE); $v=scalar@V; $r=scalar@res;
if (scalar(@V)!=scalar@res) { 
	die  "\n$file *************** $v $r\n";
	}	
for ($i=0;$i<scalar@res; $i++)  {
	$DISO=0;
	undef @info;
#	$sample++; if ($sample==($sampNumber + 1))  {last loop2;}
	undef @info;
	$lower=$i-($win-1)/2;
	$higher=$i+($win-1)/2;;
#profiles information
	push (@info,profiles($lower,$higher,$end));
#secondary structure prediction information
	push (@info, secondary($lower,$higher,$end));
#loop for solvent accessibility prediction information		
	push (@info, acc($lower,$higher,$end));
# global information
	push (@info, $expCont,(100-$expCont));	
#	push (@info, $Helix, $Beta, $Loop);
	push (@info, $lengthA,$lengthB,$lengthC);
	push (@info,$DISO);push (@info,$res[$i]);
	print FOUT "$resNum[$i] ";		
	presentIt(\@info);
	}
close (FOUT);

sub presentIt  {
        my($ref) = shift;
        my(@residue) = @{$ref};
	my $l;
	for ($l=0; $l<scalar(@residue); $l++)  {
		$residue[$l]=~s/\s//;
		if (defined($residue[$l])==0)
		 {
		 	print "\n$file\t$i\t$j\t$l";
			}
		if ($residue[$l]=~/[a-z]|A-Z]/ )  {
			print "\n$residue[$l]\t$file\t$i\t$j\t$l";
			}
		print FOUT "$residue[$l] ";
#		print "$residue[$l] ";
		}
	print FOUT "\n";
	return;
	}
system ("rm $blastpgp $hssp $saf $hsspfil $file1");
#functions to obtain properties    
#profiles
sub profiles  {
	my $lower=shift;
	my $higher=shift;
	my $end= shift;
	my @residue; 
	my @array;
	for ($j=$lower; $j<=$higher; $j++)  {
		if (($j<0) ||($j>$end)) {
			undef @residue;
			@residue=(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,100);
			push (@array, @residue);
			}
		else {
			undef @residue;
			@residue=($A[$j],$C[$j],$D[$j],$E[$j],$F[$j],$G[$j],$H[$j],$I[$j],$K[$j],$L[$j],$M[$j],$N[$j],$P[$j],$Q[$j],$R[$j],$S[$j],$T[$j],$W[$j],$Y[$j],$V[$j],0);
			push (@array, @residue);
			}
		}
		return @array;
	}
#secondary structure prediction information
sub secondary  {
	my $lower=shift;
	my $higher=shift;
	my $end= shift;
	my @secon;
	my @array;
	for ($j=$lower; $j<=$higher; $j++)  {
		if (($j<0) ||($j>$end)) {
			undef @secon;
			@secon=(100,100,100);
			push (@array, @secon);
			}
		else {
			undef @secon;
			@secon=($otH[$j],$otE[$j],$otL[$j],);
			push (@array, @secon);
			}
		}
	return @array;
	}
#function for solvent accessibility prediction information		
sub acc  {
	my $lower=shift;
	my $higher=shift;
	my $end= shift;
	my @PRE;
	my @array;
	for ($j=$lower; $j<=$higher; $j++)  {
		if (($j<0) ||($j>$end)) {
			undef @PRE;
			@PRE=(100,100);
			push (@array, @PRE);
			}
		else {
			undef @PRE;
			@PRE=($PREL[$j],$RI_A[$j]);
			push (@array, @PRE);		
			}
		}
	return @array;
	}

