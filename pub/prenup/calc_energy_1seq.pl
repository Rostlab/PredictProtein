#!/usr/bin/perl
##!/usr/local/bin/perl -w
$separation=$ARGV[0]; $file=$ARGV[1]; $prof=$ARGV[2]; $name=$ARGV[3];
#$totRes=$separation*2+1;
get_values();
$seq='';undef %E;undef @info;undef @seq;$check_file=$check2=0;
open (FILE, "$file") || die "cant open file $!";
while ($line=<FILE>) {
	$line=~ s/\n//;
	#if ($line=~ /^SEQRES/) {
	if ($line=~ /MODEL/) {
		$check_file=1;
		}
	if ($check_file==1) {
		last;
		}
	}
while ($line=<FILE>) {
	chomp$line;
	if (($line!~/^\d/)&& ($check2==0)) {
		$seq=$seq. $line;
		next;
		}
	else {
		@seq= split ('',$seq);
		$check2=1;
		}
	if ($line=~/^(\d+)\s{1,}(\d+)\s{1,}0\s{1,}8\s{1,}(.*)/) {
		$aa1=$1;$aa2=$2;$aa3=$seq[$aa1-1];$aa4=$seq[$aa2-1];$probab=$3;
		if (($aa1+$separation>=$aa2) && ($aa1-$separation<=$aa2)){ ##fixing the wrongest bug ever should not be ||
			if (($aa3 eq 'X') || ($aa4 eq 'X')) {
				$tempE=0;
				}
			else {
				$tempE= $probab*$value{$aa3}{$aa4};					
				push (@{$E{$aa1}},$tempE);
				push (@{$E{$aa2}},$tempE);
				}
			}
		}
	}
close (FILE);
if ($check_file==0)	{
	die "there is a bug in file $file !!!!!\n";
	}
##################### this section is for iimplemeting secondary structure prediction
if (!open(FILE, "$prof"))  {
       	die "cant open $prof\n";
       	}	
undef @res; undef @otH; undef @otE; undef @secC;  undef @otL; undef @PACC; undef @RI_S;
undef @PREL; undef @RI_A2; undef @resNum;undef @RI_A;undef @meida;
loop666:while ($line=<FILE>) {####################change this loop see file arath_fr13110##############
        if (($line=~/No  AA      OHEL    PHEL    RI_S    OACC    PACC    OREL    PREL    RI_A/) ||($line=~/No\tAA\tOHEL\tPHEL\tRI_S\tOACC\tPACC\tOREL\tPREL/)) {
                last loop666;
                }
        }
#find the right columns
@meida= split(/\t/,$line);
for ($o=0; $o<scalar(@meida); $o++)  {
      if ($meida[$o] eq 'No')  {$NoM=$o;}
       elsif ($meida[$o] eq 'AA')  {$AAM=$o;} elsif ($meida[$o] eq 'PHEL')  {$PHELM=$o;}
       elsif ($meida[$o] eq 'RI_S')  {$RI_SM=$o;}elsif ($meida[$o] eq 'PACC')  {$PACCM=$o;}
       elsif ($meida[$o] eq 'PREL')  {$PRELM=$o;}elsif ($meida[$o] eq 'RI_A')  {$RI_AM=$o;}
       elsif ($meida[$o] eq 'OtH')  {$otHM=$o;}elsif ($meida[$o] eq 'OtE')  {$otEM=$o;}
       elsif ($meida[$o] eq 'OtL')  {$otLM=$o;last;}
      }
loop3:while ($line=<FILE>)  {
        undef @info;
        $line=~ s/\n//;
        @info=split (/\t/,$line);
        $resNum=$info[$NoM]; $res=$info[$AAM];$secC=$info[$PHELM];$otH=$info[$otHM]; $otE=$info[$otEM]; $otL=$info[$otLM]; $RI_S=$info[$RI_SM]; $PACC=$info[$PACCM];$RI_A=$info[$RI_AM];
        $PREL=$info[$PRELM];
        if (($resNum=~/[a-z]|A-Z]/ ) ||($otH=~/[a-z]|A-Z]/ )||($otE=~/[a-z]|A-Z]/ )||($otL=~/[a-z]|A-Z]/ )||($RI_S=~/[a-z]|A-Z]/ )||($PACC=~/[a-z]|A-Z]/ )||($RI_A=~/[a-z]|A-Z]/ )||($PREL=~/[a-z]|A-Z]/ )){
               	die "\n*******@info\t$file*******\n";
               	}
       	push (@res,$res); push (@otH,$otH); push (@otE,$otE); push (@secC,$secC); push (@otL,$otL); push (@PACC,$PACC/3);push (@RI_S,$RI_S);
        push (@PREL,$PREL);$RI_A2=$RI_A; push (@RI_A2,$RI_A2); $RI_A=$RI_A/9*100;push (@resNum,$resNum);
        use integer;
        $RI_A=$RI_A*1;
        push (@RI_A,$RI_A);
        no integer;
        }
	######### residue check
for ($y=0;$y<scalar@res;$y++) {
	if ($res[$y] ne $seq[$y]) {
		print "$file $y $res[$y] ne $seq[$y]\n";
		}
	}
######################################## end of the prof section
$fout="$name.eprofcon";
open (FOUT,">$fout") || die "$fout";
for ($i=0;$i<scalar@seq;$i++) {
	 $aa=$i+1;$total=0;
         foreach  $e (@{$E{$aa}}) {
                 $total=$total+$e;
                 }
         if (scalar@seq<=$separation) {
              $totRes= scalar@seq;
               }
          elsif ((scalar@seq<=$separation*2)&&(scalar@seq>$separation)){
               if (($aa+$separation)>$#seq) {
                     if (($aa-$separation)<=0)  {
                           $totRes=scalar@seq
                           }
                     elsif (($aa-$separation)>0) {
                           $totRes=$separation+scalar@seq-$aa+1;
                           }
                     }
              else {
                    $totRes=$aa+ $separation;
                   }
              }
    	 else {
              if (($aa-$separation)<=0) {
              	$totRes=$separation+$aa;
                  }
              elsif (($aa+$separation)>$#seq) {
                       $totRes=$separation+scalar@seq-$aa+1;
                       }
               else {
                       $totRes=$separation*2+1;
                       }
                }
	$energy=$total/$totRes;
	if ($totRes==($separation*2+2)) {
		print 1;
		}
	print FOUT "$aa\t$seq[$i]\t$energy\t$totRes\t$secC[$i]\t$otH[$i]\t$otE[$i]\t$otL[$i]\n";
	}
close (FOUT);
print "created $fout file\n";
sub get_values {
        open (F, "/nfs/data5/users/ppuser/server/pub/prenup/mj-upper-right-matrix.txt") || die "can't open file $!";
        $line=<F>;chomp$line;#$line=~ s/\s//g;
        @param=split (/\t/,$line);
        while ($line=<F>) {
                chomp$line;#$line=~ s/\s//g;
                undef @number;
                @number=split (/\t/,$line);
                $l=$number[0];push (@l,$l);
                for ($z=1;$z<scalar@number;$z++) {
			if ($number[$z]!~/\d/) {
				next;
				}
                        $value{$l}{$param[$z]}=$value{$param[$z]}{$l}=$number[$z];
                        }
                }
	$value{"X"}{"X"}=0;
        close (F);
        }
