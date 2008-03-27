#!/usr/sbin/perl -w
#
# for list of SWISS-PROT: find length and location, write tab ed
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables
$loci=     "cyt|nuc|ext";
$dirSwiss= "/data/swissprot/current/";

if ($#ARGV<1){print"goal:   for list of SWISS-PROT: find length and location\n";
	      print"usage:  script list (opt: loci=[cyt|nuc|ext]\n";
	      print"opt:    loci=[cyt|nuc|ext]  (def=$loci)\n";
	      print"        dir=x (dir swiss)   (def=$dirSwiss)\n";
	      exit;}

$fileIn=$ARGV[1];
$fhin="FHIN";$fhout="FHOUT";
$fileOut= "Out-".$fileIn;
$fileOut2="Out2-".$fileIn;

foreach $_(@ARGV){ if    (/^loci=(.+)/){$loci=$1;$loci=~s/\s//g; }
		   elsif (/^dir=(.+)/) {$dirSwiss=$1;$dirSwiss=~s/\s//g; }}

$dirSwiss=&complete_dir($dirSwiss);    
				# patterns
$regexp="";
if ($loci =~ /nuc/){$regexp.="NUCLEAR\.|";}
if ($loci =~ /cyt/){$regexp.="CYTOPLASMIC\.|";}
if ($loci =~ /ext/){$regexp.="EXTRACELLULAR\.|";}

$#fileIn=0;
if    (&isSwiss($fileIn))    {push(@fileIn,$fileIn);}
elsif (&isSwissList($fileIn)){	# open list
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {$_=~s/\n//g;$file=$_; $bup=$file;
		     if (! -e $file){$tmp=$file;$tmp=~s/^[^_]+_(.).*$/$1/g;
				     $file=$dirSwiss."$tmp"."/".$file;}
		     if (! -e $file){print "--- not found swiss=$file, (nor $bup)\n";
				     next;}
		     push(@fileIn,$file);}close($fhin);}
else {
    print "*** $fileIn unrecognised\n";
    exit;}
		     # read list
%tmp=0;
&open_file("$fhout", ">$fileOut");
foreach $file (@fileIn){
    &open_file("$fhin", "$file");
    $loci=$len="";
#    print "x.x reading $file\n";
    $_=<$fhin>;$_=~s/^ID.+ (\d+)\s+AA\..*$/$1/;$len=$_;$len=~s/\s//g;
    while (<$fhin>) {$_=~s/\n//g;
		     if (/^CC   -!- SUBCELLULAR LOCATION:/ &&
			 /$regexp/){
			 $_=~s/^CC   -!- SUBCELLULAR LOCATION:\s+//g;
			 $_=~s/\s|\.//g;$_=~tr/[A-Z]/[a-z]/;
			 $loci=substr($_,1,3);
			 last;}}close($fhin);
    if (length($loci)>0 && length($len)>0){
	$id=$file; $id=~s/^.*\///g; 
	if    ($loci =~/^nuc/){$lociNum=1;}
	elsif ($loci =~/^cyt/){$lociNum=2;}
	elsif ($loci =~/^ext/){$lociNum=3;}
	print  "$id\t$loci\t$lociNum\t$len\n";
	print $fhout "$id\t$loci\t$lociNum\t$len\n";
	if (! defined $tmp{$lociNum}){$tmp{$lociNum}=$len."\t";}
	else{$tmp{$lociNum}.=$len."\t";}}
}close($fhout);

&open_file("$fhout", ">$fileOut2");
@tmp1=split(/\t/,$tmp{1});
@tmp2=split(/\t/,$tmp{2});
@tmp3=split(/\t/,$tmp{3});
print $fhout  "nuc\tcyt\text\n";
$max=$#tmp1;if ($#tmp2>$max){$max=$#tmp2;}if($#tmp3>$max){$max=$#tmp3;}
foreach $it (1..$max){
    if (defined $tmp1[$it]){$tmp1=$tmp1[$it];}else{$tmp1="";}
    if (defined $tmp2[$it]){$tmp2=$tmp2[$it];}else{$tmp2="";}
    if (defined $tmp3[$it]){$tmp3=$tmp3[$it];}else{$tmp3="";}
    print $fhout "$tmp1\t$tmp2\t$tmp3\n";}
close($fhout);
exit;
