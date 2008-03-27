#!/usr/sbin/perl -w
#
# reads files outFromExtractHeader.rdb, 
# greps ids in interval of threshold (20-35%)
#
$[ =1 ;

				# include libraries
push (@INC, "/home/rost/perl") ;if (! defined $ENV{'PERLLIB'}){push(@INC,$ENV{'PERLLIB'});}
require "ctime.pl";
require "lib-ut.pl"; require "lib-prot.pl"; require "lib-comp.pl";
				# initialise variables
if ($#ARGV<1){print"goal:   reads files outFromExtractHeader.rdb,\n";
	      print"        greps ids in interval\n";
	      print"usage:  script hsspHeader.rdb (or many) ide=x1-x2 len=y1-y2\n";
	      exit;}

$fhin="FHIN";$fhout="FHOUT";
$fileOut="OUTervall".$$.".tmp";
				# ------------------------------
$#fileIn=0;			# read command line
foreach $arg(@ARGV){if    (-e $arg && &is_rdbf($arg)){push(@fileIn,$arg);}
		    elsif ($arg =~/ide=(.+)/)        {$ide=$1;}
		    elsif ($arg =~/len=(.+)/)        {$len=$1;}
		    else                             {print "*** not understood: '$arg'\n";
						      die;}}
				# ------------------------------
				# error check
if ($#fileIn<=0){print "*** input files have to be in RDB format\n";die;}
if (! defined $ide||(length($ide)<2)){print "*** GIVE ide=x1-x2 (x1-x2,x3-x4)\n";die;}
if (! defined $len||(length($len)<2)){
    print "-*- NOTE length constraint not given\n";
    $len="*";}
else { 
    @len=&get_range($len);}	# lengths range
@ide=&get_range($ide);		# ides range  (30-35 -> @ide=30,31,32,33,34,35)
&myprt_array(",","xx ide=",@ide);
&myprt_array(",","xx len=",@len);

				# ------------------------------
				# read files
foreach $fileIn(@fileIn){
    print "--- open file $fileIn\n";
    &open_file("$fhin", "$fileIn");
    while (<$fhin>) {
	if (/^\#/ || /^NoAll/ || /^\s*5N/){
	    next;}
	$_=~s/\n//g;$line=$_;
	$_=~s/^[\s\t]*|[\s\t]*$//g;
	@tmp=split(/\t/,$_);
	$ideRd=$tmp[6];$ideRd=~s/\s//g;$lenRd=$tmp[10];$lenRd=~s/\s//g;
	$Llen=$Lide=0;
	if ($len eq "*"){$Llen=1;$Lok=1;}
	else     {$Lok=0;foreach $tmp(@len){if ($tmp == $lenRd){$Lok=1; 
							    last;}}
		  if ($Lok){$Llen=1;}}
	if ($Lok){$Lok=0;foreach $tmp(@ide){if ($tmp == $ideRd){$Lok=1; 
								last;}}
		  if ($Lok){$Lide=1;}}
	if ( $Lide && $Llen){$ideThresh=&getDistanceNewCurveIde($lenRd);
			     $dis=int($ideRd-$ideThresh);
			     print "xx ok for ide=$ideRd, len=$lenRd, lide=$Lide, llen=$Llen\n";
			     if (defined $res{"$dis"}){
				 $res{"$dis"}.=",$line";}
			     else{
				 $res{"$dis"}="$line";}}
#	else {print "xx not for ide=$ideRd, len=$lenRd, lide=$Lide, llen=$Llen\n";}
    }				# end reading one file
    close($fhin);
}				# end of loop over all input files

				# ------------------------------
				# write all ids
$ct=0;
&open_file("$fhout",">$fileOut"); 
print $fhout 
    "# Perl-RDB \n#\n",
    "No\tID1\tID2\tIDE\tDIS\tWSIM\tLEN1\tLEN2\tLALI\tNGAP\tLGAP\tIFIR\tILAS\tJFIR\tJLAS\n",
    "5N\t\t\t\t\t\t\t\t\t\n";
foreach $dis (-100 .. 100){
    if (! defined $res{"$dis"}){
	next;}
    print "--- found for dis=$dis\n";
    @tmp=split(/,/,$res{"$dis"});
    foreach $tmp(@tmp){
	next if (length($tmp)<5);
	++$ct;
	$tmp=~s/^\s*|\s*$//g;
	@tmp2=split(/\t/,$tmp);
	print $fhout 
	    "$ct\t$tmp2[3]\t$tmp2[4]\t",
	    "$tmp2[6]\t$dis\t$tmp2[7]\t$tmp2[8]\t$tmp2[9]\t$tmp2[10]\t",
	    "$tmp2[11]\t$tmp2[12]\t$tmp2[13]\t$tmp2[14]\t$tmp2[15]\t$tmp2[16]\n";
    }}
close($fhout);
print "--- no found: $ct, output in $fileOut\n";

exit;
