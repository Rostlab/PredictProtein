#!/usr/local/bin/perl -w
#create the first in_test. the nodes' correspond to the amino acids in the following order:
#1-A,2-C,3-D,4-E,5-f,6-g,7-h,8-i,9-k,10-l,11-M,12-n,13-p,14-q,15-r,16-s,17-t,18-w,19-y,20-v,21-z
#the nodes of secondary structure are:
#1-G,2-H,3-I,4-E,5-B,6-T,7-S,8-L
#non strict /home/schles/work/palm-share/antigenicity/scr/jct48-R4-N35HN-209-len-expC-RI_A-term00303-ON2 (-4)
#strict /home/schles/work/palm-share/antigenicity/scr/jct62-R4-N35HN-209-len-expC-RI_A-term00303-ON2 (24)
#
#
use Cwd;
use File::Copy;
if (@ARGV<4)  {
	die "\nUsage: $0 [fasta] [outfile] [output-window] [mode]\n";
	}

$dir="/data2/ppuser/server/pub/profbval"; # profbval home
$tmp_file=$ARGV[0];
$mode=$ARGV[3];
@arrTmp= split(/\//, $tmp_file);
$file= pop @arrTmp;
#$file=~ s/\.fasta//;
$id= $file;
$id=~ s/\.fasta//;
#$stretch=$ARGV[0];;
$win=9;
#$jct="jct62-R4-N35HN-209-len-expC-RI_A-term00303-ON2";
$jct="$dir/jct63-R1-209-237433-ON2";

$resultsdir="$dir/temp";

#$thre=$ARGV[4];
$ON= 2;$sampIn=0;
$IN=209;
$all=' ';
$datafile=$id . ".data";
#$dir="/data2/ppuser/server/pub/profbval";
undef @order;

print "\n########counting samples #######\n";
#print "$dir\/temp\/$datafile\n"x5; 
open (F, "$ARGV[0]") || die "siyut ahhh";
<F>;
while ($line=<F>)  {
 	$all= $all . $line;
	}
$all=~s/\s//g;
@all= split ('', $all);
$sampIn= scalar@all;	
close (F);
print "\n####working on $id\n";
print "Line 50:$sampIn samples\n";if ($sampIn==0)  {die "sequence has 0 residues??!"}	 
$inTest="$resultsdir/$id-in_test";
print "inTest=$inTest\n"x5;
$inOutTest="$resultsdir/$id-in-out-test";
#$jctFile="jct$u-samp10states-$sampIn-Balanced-win9";
if ($id=~/help/)  {
	$idtemp=$id;
	$idtemp=~s/help//;
	$partest="$resultsdir/$idtemp-partest";
	}
else {
	$partest="$resultsdir/$id-partest";
	}
$testOutFile= "$resultsdir/$id-test-out-35HN-209-win9";	
#print "1\n";
open (FOUT, ">$inTest") || die "error0";
printf FOUT "* overall: (A,T25,I8)\nNUMIN                 :      %3d\nNUMSAMFILE            :   %6d\n*",$IN,$sampIn;
print FOUT "\n* samples: count (A8,I8) NEWLINE 1..NUMIN (25I6)\n";
print "#####collecting all samples#######\n";
$h=1;
undef @res;undef $end;undef@PREL;  undef @otL; undef @otE;
undef @otH;undef @RI_A;$expCon1=$expCon2=0;undef @RI_S;undef @outPut;
undef @secC;  $lengthA=$lengthB=$lengthC=0;undef @access;
undef @A;undef @C;undef @D;undef @E;undef @F;undef @G;undef @H;undef @I;undef @K;undef @L;
undef @M;undef @N;undef @P;undef @Q;undef @R;undef @S;undef @T;undef @V;undef @W;undef @Y;undef @GS;undef @RI_s;undef @RI_ns;
chomp($id);undef @RI_S;undef @yes;
open (FILE, "$dir/temp/$datafile") || die "tinofet $datafile $!";
while ($line=<FILE>)  {
	@stuff=split(' ', $line);
#	$resNum=$stuff[0];\
	$A=$stuff[1];$C=$stuff[2];$D=$stuff[3];$E=$stuff[4];$F=$stuff[5];$G=$stuff[6];$H=$stuff[7];$I=$stuff[8];
	$K=$stuff[9];$L=$stuff[10];$M=$stuff[11];$N=$stuff[12];$P=$stuff[13];$Q=$stuff[14];$R=$stuff[15];$S=$stuff[16];
	$T=$stuff[17];$W=$stuff[18];$Y=$stuff[19];$V=$stuff[20];			
	$otH=$stuff[22];$otE=$stuff[23];$otL=$stuff[24];$PREL=$stuff[25];$RI_A=$stuff[26];
	$expCon1=$stuff[27];$expCon2=$stuff[28];$lengthA=$stuff[29];$lengthB=$stuff[30];$lengthC=$stuff[31];$outPut=$stuff[32];$res=$stuff[33];
	push (@res,$res);
	if ($PREL>=16) {push (@access, "e");} else {push(@access, "b");}
	push (@A,$A) ;push (@C,$C);push (@D,$D);push (@E,$E);push (@F,$F);push(@G,$G);push(@H,$H);push(@I,$I);push(@K,$K);push(@L,$L);
	push (@M,$M);push(@N,$N);push(@P,$P);push(@Q,$Q);push(@R,$R);push(@S,$S);push(@T,$T);push(@V,$V);push(@W,$W);push(@Y,$Y);			
	push (@otH,$otH);push (@outPut,$outPut);
	push (@otE,$otE);
	push (@secC,$secC);
	push (@otL,$otL);
	push (@RI_A,$RI_A);
	push (@Bnew,$Bnew);
	push (@PREL,$PREL);;$end=scalar@PREL-1;
	}		
loop4:for ($i=0;$i<scalar@PREL; $i++)  {		
	$k=0;undef @info;
	if ($h==($sampIn + 1))  {
		last loop4;
		}
	$lower=$i-($win-1)/2;
	$higher=$i+($win-1)/2;
	$lowerPREL=$i-(5-1)/2;
	$higherPREL=$i+(5-1)/2;
	$lowerSec=$i-(3-1)/2;
	$higherSec=$i+(3-1)/2;
#profiles information
	push (@info,profiles($lower,$higher,$#PREL));
#secondary structure prediction information
	push (@info, secondary($lowerSec,$higherSec,$#PREL));
#loop for solvent accessibility prediction information		
	push (@info, acc($lowerPREL,$higherPREL,$#PREL));
# global information
	push (@info,$RI_A[$i] );
	push (@info, $expCon1,$expCon2);	
#	push (@info, $Helix, $Beta, $Loop);
	push (@info, $lengthA,$lengthB,$lengthC);
#	push (@info,$cA,$cC,$cD,$cE,$cF,$cG,$cH,$cI,$cK,$cL,$cM,$cN,$cP,$cQ,$cR,$cS,$cT,$cV,$cW,$cY);
	printf FOUT "ITSAM:%10d\n",$h;
	presentIt(\@info);
	$h++;
#	presentIt(\@info);		
#	print FOUT "\n" unless $k==25;
	}
print FOUT "//"; 
close(FOUT);
print "\nnumber of samples saved in memory:$h\n"; 
#Mark2:	
print "\n########creating out-test file ######\n";

open (FOUT, ">$inOutTest") || die "cant open file $!";
printf FOUT "* overall: (A,T25,I8)\nNUMOUT                :        $ON\nNUMSAMFILE            :%9d\n*",$sampIn;
print FOUT "\n* samples: count (I8) SPACE 1..NUMOUT (25I6)\n";
for ($i=0; $i<scalar@outPut;$i++)  {
	$ii=$i+1;
	if ($outPut[$i]==100)  {
		$GS[$i]='G';
		}
	else {
		$GS[$i]='-';
		}
	printf FOUT "%8d",$ii; $m=100- $outPut[$i];
       	printf FOUT "  %5d%6d\n",$outPut[$i],$m;
	}
print FOUT "//"; 
close (FOUT);
open (FOUT, ">$partest")  || die "can't open file $!";
print FOUT "* I8\n";
printf FOUT "NUMIN                 :      %3d\n",$IN;
print FOUT "NUMHID                :       35\n";
print FOUT "NUMOUT                :        $ON\n";
print FOUT "NUMLAYERS             :        2\n";
printf FOUT "NUMSAM                :%9d\n",$sampIn;
print FOUT "NUMFILEIN_IN          :        1\n";
print FOUT "NUMFILEIN_OUT         :        1\n";
print FOUT "NUMFILEOUT_OUT        :        1\n";
print FOUT "NUMFILEOUT_JCT        :        1\n";
print FOUT "STPSWPMAX             :        0\n";
print FOUT "STPMAX                :        0\n";
print FOUT "STPINF                :        1\n";
print FOUT "ERRBINSTOP            :        0\n";
print FOUT "BITACC                :      100\n";
print FOUT "DICESEED              :   100025\n";
print FOUT "DICESEED_ADDJCT       :        0\n";
print FOUT "LOGI_RDPARWRT         :        1\n";
print FOUT "LOGI_RDINWRT          :        0\n";
print FOUT "LOGI_RDOUTWRT         :        0\n";
print FOUT "LOGI_RDJCTWRT         :        0\n";
print FOUT "* --------------------\n";
print FOUT "* F15.6\n";
print FOUT "EPSILON               :        0.030000\n";
print FOUT "ALPHA                 :        0.300000\n";
print FOUT "TEMPERATURE           :        1.000000\n";
print FOUT "ERRSTOP               :        0.000000\n";
print FOUT "ERRBIAS               :        0.000000\n";
print FOUT "ERRBINACC             :        0.200000\n";
print FOUT "THRESHOUT             :        0.500000\n";
print FOUT "DICEITRVL             :        0.100000\n";
print FOUT "* --------------------\n";
print FOUT "* A132\n";
print FOUT "TRNTYPE               : ONLINE\n";
print FOUT "TRGTYPE               : SIG\n";
print FOUT "ERRTYPE               : DELTASQ\n";
print FOUT "MODEPRED              : sec\n";
print FOUT "MODENET               : 1st,unbal\n";
print FOUT "MODEIN                : win=5,loc=aa\n";
print FOUT "MODEOUT               : KN\n";
print FOUT "MODEJOB               : mode_of_job\n";
print FOUT "FILEIN_IN             : $inTest\n";
print FOUT "FILEIN_OUT            : $inOutTest\n";
print FOUT "FILEIN_JCT            : $jct\n";
print FOUT "FILEOUT_OUT           : $testOutFile\n";
print FOUT "FILEOUT_JCT           : jct_crap\n";
print FOUT "FILEOUT_ERR           : NNo_tst_err.dat\n";
print FOUT "FILEOUT_YEAH          : NNo-yeah1637.tmp\n";
print FOUT "//\n";
close FOUT;
#system ("/home2/schles/palm-share/antigenicity/NET/for/NetRun4.LINUX $partest");
system ("$dir/NetRun4.LINUX $partest");
system ("rm $inTest");
system ("rm $inOutTest");
system ("rm $partest");
system ("rm $resultsdir/$datafile");

############ normalizing output ######################
$totalDiff=$sum=0;
undef@preds;undef@predns;
open (F, "$testOutFile") || die " test file doesnt exist";
for ($r=0; $r<43; $r++) {
	<F>;
	}
while ($line=<F>)  {
	if ($line=~ /^(.{8})(.{5})(.{4})/)  {
		$result2=$3;
		$result1=$2;
		$result2=~ s/\s//g;$result1=~ s/\s//g;
		$diff=$result1/($result1+$result2);
		if ($diff>1) {push (@order,'D');} 
		else {push (@order,'O');}
		push (@diff,$diff);
		}
	}
close (F);
$l=scalar@diff;
system ("rm $testOutFile");
open (FOUT,">$ARGV[1]") || die "cant create output file $ARGV[1]\n"; 
$wind=$ARGV[2];
#################### smooth it - window of n ##################
printf FOUT "PFRMAT DR\n";
printf FOUT "TARGET %s\n",$target_name;
printf FOUT "AUTHOR XXXX-XXXX-XXXX\n"; 
printf FOUT "REMARK the method was optimized to predict normalized B-values and not disorder\n";
printf FOUT "REMARK we do not submit 2 state disorder prediction because our method was not optimized to do it \n";
printf FOUT "REMARK Insetad, we print 'O' for everything in that field\n";
printf FOUT "METHOD PROFbval: predicting normalized B-values from sequence\n";
printf FOUT "MODEL 1\n";
for ($i=0;$i<scalar@diff;$i++) {
	printf FOUT "%c %c %1.2f\n",$res[$i[,$order[$i],$diff[$i];
	}
printf "END\n";
	
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
		printf FOUT "%6d",$residue[$l];
		$k++;
		if ($k==25)  {
			print FOUT "\n";
			$k=0;
			}
		}
	print FOUT "\n"; $k=0;
	return;
	}
#functions to obtain properties    
#profiles
sub profiles  {
	my $lower=shift;
	my $higher=shift;
	my $end= shift;
	my @residue; 
	my @array;
	for ($j=$lower; $j<=$higher; $j++)  {
		if (($j<0) ||($j>$end)) { ##i know its wrong, but this is the way i trained it
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
			@secon=(0,0,0);
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
			@PRE=(100);
			push (@array, @PRE);
			}
		else {
			undef @PRE;
			@PRE=($PREL[$j]);
			push (@array, @PRE);		
			}
		}
	return @array;
	}	
